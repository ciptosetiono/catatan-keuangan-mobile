import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/transaction_model.dart';
import 'wallet_service.dart';

class TransferService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference transfersRef = FirebaseFirestore.instance
      .collection('transactions');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final WalletService _walletService = WalletService();

  // Cache lokal
  List<TransactionModel> _localCache = [];

  // ======================= Query Builder =======================
  Query<Map<String, dynamic>> _buildQuery({
    String? fromWalletId,
    String? toWalletId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'transfer');

    if (fromWalletId != null) {
      query = query.where('fromWalletId', isEqualTo: fromWalletId);
    }
    if (toWalletId != null) {
      query = query.where('toWalletId', isEqualTo: toWalletId);
    }
    if (fromDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }
    if (toDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(toDate),
      );
    }

    return query.orderBy('date', descending: true);
  }

  // ======================= Stream / Get Transfers =======================
  Stream<List<TransactionModel>> getTransfers({
    String? fromWalletId,
    String? toWalletId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async* {
    final fromQuery = _buildQuery(
      fromWalletId: fromWalletId,
      fromDate: fromDate,
      toDate: toDate,
    );
    final toQuery = _buildQuery(
      toWalletId: toWalletId,
      fromDate: fromDate,
      toDate: toDate,
    );

    await for (var snaps in Rx.combineLatest2(
      fromQuery.snapshots(includeMetadataChanges: true),
      toQuery.snapshots(includeMetadataChanges: true),
      (QuerySnapshot fromSnap, QuerySnapshot toSnap) {
        final allDocsMap = <String, DocumentSnapshot>{};

        for (final doc in fromSnap.docs) allDocsMap[doc.id] = doc;
        for (final doc in toSnap.docs) allDocsMap[doc.id] = doc;

        final allDocs =
            allDocsMap.values.toList()..sort((a, b) {
              final dateA = (a['date'] as Timestamp).toDate();
              final dateB = (b['date'] as Timestamp).toDate();
              return dateB.compareTo(dateA);
            });

        return allDocs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();
      },
    )) {
      _localCache = snaps;
      yield snaps;
    }
  }

  Stream<List<TransactionModel>> getTransfersByWallet(String walletId) {
    return getTransfers(fromWalletId: walletId, toWalletId: walletId);
  }

  // ======================= Add / Update / Delete =======================
  Future<void> addTransfer(TransactionModel transfer) async {
    if (transfer.fromWalletId == null || transfer.toWalletId == null) {
      throw Exception('Wallet ID tidak boleh null');
    }
    if (transfer.fromWalletId == transfer.toWalletId) {
      throw Exception('From Wallet dan To Wallet tidak boleh sama');
    }

    final docRef = transfersRef.doc();
    final newTransfer = transfer.copyWith(id: docRef.id);

    // Update cache lokal dulu
    _localCache.add(newTransfer);

    // Update saldo wallet lokal
    final fromWallet = await _walletService.getWalletById(
      transfer.fromWalletId!,
    );
    final toWallet = await _walletService.getWalletById(transfer.toWalletId!);

    await _walletService.updateWallet(
      fromWallet.copyWith(
        currentBalance: fromWallet.currentBalance - transfer.amount,
      ),
    );
    await _walletService.updateWallet(
      toWallet.copyWith(
        currentBalance: toWallet.currentBalance + transfer.amount,
      ),
    );

    // Firestore
    try {
      await docRef.set(newTransfer.toMap());
      debugPrint("✅ Transfer added with ID: ${newTransfer.id}");
    } catch (e) {
      debugPrint("⚠️ Failed to add transfer to Firestore: $e");
    }
  }

  Future<void> updateTransfer(
    TransactionModel oldData,
    TransactionModel newData,
  ) async {
    final index = _localCache.indexWhere((tx) => tx.id == oldData.id);
    if (index != -1) {
      final oldTx = _localCache[index];
      _localCache[index] = newData;

      // Update wallet balances
      final oldFromWallet = await _walletService.getWalletById(
        oldTx.fromWalletId!,
      );
      final oldToWallet = await _walletService.getWalletById(oldTx.toWalletId!);
      final newFromWallet = await _walletService.getWalletById(
        newData.fromWalletId!,
      );
      final newToWallet = await _walletService.getWalletById(
        newData.toWalletId!,
      );

      // Rollback saldo lama
      await _walletService.updateWallet(
        oldFromWallet.copyWith(
          currentBalance: oldFromWallet.currentBalance + oldTx.amount,
        ),
      );
      await _walletService.updateWallet(
        oldToWallet.copyWith(
          currentBalance: oldToWallet.currentBalance - oldTx.amount,
        ),
      );

      // Apply saldo baru
      await _walletService.updateWallet(
        newFromWallet.copyWith(
          currentBalance: newFromWallet.currentBalance - newData.amount,
        ),
      );
      await _walletService.updateWallet(
        newToWallet.copyWith(
          currentBalance: newToWallet.currentBalance + newData.amount,
        ),
      );
    }

    // Update Firestore
    try {
      await transfersRef.doc(oldData.id).update(newData.toMap());
      debugPrint("✅ Transfer ${oldData.id} updated on Firestore and cache");
    } catch (e) {
      debugPrint("⚠️ Failed to update transfer: $e");
    }
  }

  Future<void> deleteTransfer(String id) async {
    final index = _localCache.indexWhere((tx) => tx.id == id);
    if (index == -1) {
      try {
        await transfersRef.doc(id).delete();
        return;
      } catch (e) {
        debugPrint("⚠️ Failed to delete transfer $id from Firestore: $e");
        return;
      }
    }

    final tx = _localCache.removeAt(index);

    // Adjust wallet balances
    final fromWallet = await _walletService.getWalletById(tx.fromWalletId!);
    final toWallet = await _walletService.getWalletById(tx.toWalletId!);

    await _walletService.updateWallet(
      fromWallet.copyWith(
        currentBalance: fromWallet.currentBalance + tx.amount,
      ),
    );
    await _walletService.updateWallet(
      toWallet.copyWith(currentBalance: toWallet.currentBalance - tx.amount),
    );

    // Firestore
    try {
      await transfersRef.doc(id).delete();
      debugPrint("✅ Transfer $id deleted from Firestore and cache");
    } catch (e) {
      debugPrint("⚠️ Failed to delete transfer $id from Firestore: $e");
    }
  }

  Future<TransactionModel?> getTransferById(String id) async {
    final cached =
        _localCache.where((tx) => tx.id == id).isNotEmpty
            ? _localCache.firstWhere((tx) => tx.id == id)
            : null;
    if (cached != null) return cached;

    final doc = await transfersRef.doc(id).get();
    if (!doc.exists) return null;
    final transfer = TransactionModel.fromFirestore(doc);
    _localCache.add(transfer);
    return transfer;
  }
}
