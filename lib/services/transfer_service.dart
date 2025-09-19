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

        for (final doc in fromSnap.docs) {
          allDocsMap[doc.id] = doc;
        }
        for (final doc in toSnap.docs) {
          allDocsMap[doc.id] = doc;
        }

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
    final batch = FirebaseFirestore.instance.batch();

    try {
      // 1. Ambil wallet lama (sudah terpotong old transfer)
      final oldFromWallet = await _walletService.getWalletById(
        oldData.fromWalletId!,
      );
      final oldToWallet = await _walletService.getWalletById(
        oldData.toWalletId!,
      );

      // 2. Rollback saldo lama (balik ke kondisi sebelum old transfer)
      var rollbackFromBalance = oldFromWallet.currentBalance + oldData.amount;
      var rollbackToBalance = oldToWallet.currentBalance - oldData.amount;

      // 3. Siapkan map wallet untuk update saldo (biar tidak dobel query)
      final Map<String, double> walletBalances = {
        oldFromWallet.id!: rollbackFromBalance,
        oldToWallet.id!: rollbackToBalance,
      };

      // 4. Apply transaksi baru di atas saldo rollback
      walletBalances[newData.fromWalletId!] =
          (walletBalances[newData.fromWalletId!] ??
              (await _walletService.getWalletById(
                newData.fromWalletId!,
              )).currentBalance) -
          newData.amount;

      walletBalances[newData.toWalletId!] =
          (walletBalances[newData.toWalletId!] ??
              (await _walletService.getWalletById(
                newData.toWalletId!,
              )).currentBalance) +
          newData.amount;

      // 5. Push update semua wallet ke batch
      for (final entry in walletBalances.entries) {
        final wallet = await _walletService.getWalletById(entry.key);
        _walletService.updateWalletBatch(
          batch,
          wallet.copyWith(currentBalance: entry.value),
        );
      }

      // 6. Update dokumen transfer
      batch.update(transfersRef.doc(oldData.id), newData.toMap());

      // 7. Commit batch (atomic)
      await batch.commit();

      // 8. Update cache lokal
      final index = _localCache.indexWhere((tx) => tx.id == oldData.id);
      if (index != -1) {
        _localCache[index] = newData;
      }

      debugPrint(
        "✅ Transfer ${oldData.id} updated with rollback+apply correctly",
      );
    } catch (e) {
      debugPrint("⚠️ Failed to update transfer: $e");
      rethrow;
    }
  }

  Future<void> deleteTransfer(String id) async {
    final batch = FirebaseFirestore.instance.batch();

    try {
      // 1. Ambil transfer dari cache
      TransactionModel? tx;
      final index = _localCache.indexWhere((t) => t.id == id);
      if (index != -1) {
        tx = _localCache.removeAt(index);
        debugPrint("✅ Removed transfer from cache");
      } else {
        // Ambil dari Firestore kalau tidak ada di cache
        final doc = await transfersRef.doc(id).get();
        if (!doc.exists) {
          debugPrint("⚠️ Transfer $id not found anywhere, skip");
          return;
        }

        final data = doc.data();
        if (data == null) {
          debugPrint("⚠️ Transfer $id doc is empty, skip rollback");
          return;
        }
        tx = TransactionModel.fromMap(data as Map<String, dynamic>);

        debugPrint("✅ Transfer $id loaded from Firestore for rollback");
      }

      // 2. Rollback wallet "from" & "to" (jika ada)
      try {
        final fromWallet = await _walletService.getWalletById(tx.fromWalletId!);
        if (fromWallet != null) {
          _walletService.updateWalletBatch(
            batch,
            fromWallet.copyWith(
              currentBalance: fromWallet.currentBalance + tx.amount,
            ),
          );
          debugPrint("✅ fromWallet rollbacked");
        }
      } catch (_) {}

      try {
        final toWallet = await _walletService.getWalletById(tx.toWalletId!);
        if (toWallet != null) {
          _walletService.updateWalletBatch(
            batch,
            toWallet.copyWith(
              currentBalance: toWallet.currentBalance - tx.amount,
            ),
          );
          debugPrint("✅ toWallet rollbacked");
        }
      } catch (_) {}

      // 3. Hapus dokumen transfer
      batch.delete(transfersRef.doc(id));

      // 4. Commit batch
      await batch.commit();

      debugPrint("✅ Transfer $id deleted with wallet rollback if possible");
    } catch (e) {
      debugPrint("⚠️ Failed to delete transfer: $e");
      rethrow;
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
