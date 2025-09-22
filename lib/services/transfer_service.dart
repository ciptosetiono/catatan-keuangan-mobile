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

  // Local cache
  final List<TransactionModel> _localCache = [];

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

  // ======================= Stream Transfers =======================
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
            allDocsMap.values.toList()..sort(
              (a, b) =>
                  (b['date'] as Timestamp).compareTo(a['date'] as Timestamp),
            );

        return allDocs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();
      },
    )) {
      _localCache.clear();
      _localCache.addAll(snaps);
      yield snaps;
    }
  }

  Stream<List<TransactionModel>> getTransfersByWallet(String walletId) {
    return getTransfers(fromWalletId: walletId, toWalletId: walletId);
  }

  // ======================= Add Transfer =======================
  Future<TransactionModel> addTransfer(TransactionModel transfer) async {
    if (transfer.fromWalletId == null || transfer.toWalletId == null) {
      throw Exception('Wallet ID tidak boleh null');
    }
    if (transfer.fromWalletId == transfer.toWalletId) {
      throw Exception('From Wallet dan To Wallet tidak boleh sama');
    }

    final docRef = transfersRef.doc();
    final newTransfer = transfer.copyWith(id: docRef.id);

    final batch = _db.batch();

    // Update wallets
    final fromWallet = await _walletService.getWalletById(
      transfer.fromWalletId!,
    );

    if (fromWallet != null) {
      _walletService.updateWalletBatch(
        batch,
        fromWallet.copyWith(
          currentBalance: fromWallet.currentBalance - transfer.amount,
        ),
      );
    }
    final toWallet = await _walletService.getWalletById(transfer.toWalletId!);
    if (toWallet != null) {
      _walletService.updateWalletBatch(
        batch,
        toWallet.copyWith(
          currentBalance: toWallet.currentBalance + transfer.amount,
        ),
      );
    }

    batch.set(docRef, newTransfer.toMap());

    await batch.commit();

    _localCache.add(newTransfer);
    debugPrint("✅ Transfer added with ID: ${newTransfer.id}");

    return newTransfer;
  }

  // ======================= Update Transfer =======================
  Future<TransactionModel> updateTransfer(
    TransactionModel oldData,
    TransactionModel newData,
  ) async {
    final batch = _db.batch();

    try {
      // 1️⃣ Ambil wallet lama (boleh null)
      final oldFromWallet =
          oldData.fromWalletId != null
              ? await _walletService.getWalletById(oldData.fromWalletId!)
              : null;
      final oldToWallet =
          oldData.toWalletId != null
              ? await _walletService.getWalletById(oldData.toWalletId!)
              : null;

      final walletBalances = <String, double>{};

      // 2️⃣ Rollback saldo lama jika wallet ada
      if (oldFromWallet != null) {
        walletBalances[oldFromWallet.id] =
            oldFromWallet.currentBalance + oldData.amount;
      }
      if (oldToWallet != null) {
        walletBalances[oldToWallet.id] =
            oldToWallet.currentBalance - oldData.amount;
      }

      // 3️⃣ Ambil wallet baru (harus ada untuk update)
      final newFromWallet = await _walletService.getWalletById(
        newData.fromWalletId!,
      );
      final newToWallet = await _walletService.getWalletById(
        newData.toWalletId!,
      );

      if (newFromWallet == null || newToWallet == null) {
        throw Exception("New wallet not found");
      }

      // 4️⃣ Apply transfer baru di atas rollback
      walletBalances[newData.fromWalletId!] =
          (walletBalances[newData.fromWalletId!] ??
              newFromWallet.currentBalance) -
          newData.amount;
      walletBalances[newData.toWalletId!] =
          (walletBalances[newData.toWalletId!] ?? newToWallet.currentBalance) +
          newData.amount;

      // 5️⃣ Update saldo semua wallet di batch
      for (final entry in walletBalances.entries) {
        final wallet = await _walletService.getWalletById(entry.key);
        if (wallet != null) {
          final walletRef = FirebaseFirestore.instance
              .collection('wallets')
              .doc(wallet.id);
          batch.update(walletRef, {'currentBalance': entry.value});
        }
      }

      // 6️⃣ Update dokumen transfer
      final transferRef = _db.collection('transactions').doc(oldData.id);
      batch.update(transferRef, newData.toMap());

      // 7️⃣ Commit batch (atomic)
      await batch.commit();

      // 8️⃣ Update cache lokal
      final index = _localCache.indexWhere((tx) => tx.id == oldData.id);
      if (index != -1) _localCache[index] = newData;

      debugPrint(
        "✅ Transfer ${oldData.id} updated successfully (rollback optional)",
      );
      return newData;
    } catch (e) {
      debugPrint("⚠️ Failed to update transfer: $e");
      rethrow;
    }
  }

  // ======================= Delete Transfer =======================
  Future<void> deleteTransfer(String id) async {
    final batch = _db.batch();

    // Ambil transfer dari cache atau Firestore
    TransactionModel? tx;
    final index = _localCache.indexWhere((t) => t.id == id);
    if (index != -1) {
      tx = _localCache.removeAt(index);
    } else {
      final doc = await transfersRef.doc(id).get();
      if (!doc.exists) {
        debugPrint("⚠️ Transfer $id not found, skip deletion");
        return;
      }
      tx = TransactionModel.fromFirestore(doc);
    }

    // Rollback fromWallet
    if (tx.fromWalletId != null) {
      final fromWallet = await _walletService.getWalletById(tx.fromWalletId!);
      if (fromWallet != null) {
        _walletService.updateWalletBatch(
          batch,
          fromWallet.copyWith(
            currentBalance: fromWallet.currentBalance + tx.amount,
          ),
        );
      } else {
        debugPrint(
          "⚠️ fromWallet ${tx.fromWalletId} not found, skipping rollback",
        );
      }
    }

    // Rollback toWallet
    if (tx.toWalletId != null) {
      final toWallet = await _walletService.getWalletById(tx.toWalletId!);
      if (toWallet != null) {
        _walletService.updateWalletBatch(
          batch,
          toWallet.copyWith(
            currentBalance: toWallet.currentBalance - tx.amount,
          ),
        );
      } else {
        debugPrint("⚠️ toWallet ${tx.toWalletId} not found, skipping rollback");
      }
    }

    // Hapus transfer
    batch.delete(transfersRef.doc(id));
    await batch.commit();

    debugPrint("✅ Transfer $id deleted with rollback if possible");
  }

  // ======================= Get Transfer By ID =======================
  Future<TransactionModel?> getTransferById(String id) async {
    TransactionModel? cached;
    try {
      cached = _localCache.firstWhere((tx) => tx.id == id);
      return cached;
    } catch (_) {}

    final doc = await transfersRef.doc(id).get();
    if (!doc.exists) return null;

    final transfer = TransactionModel.fromFirestore(doc);
    _localCache.add(transfer);
    return transfer;
  }
}
