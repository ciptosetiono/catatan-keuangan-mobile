import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import 'wallet_service.dart';
import 'package:rxdart/rxdart.dart';

class TransferService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference transfersRef = FirebaseFirestore.instance
      .collection('transactions');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final WalletService _walletService = WalletService();

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
  }) {
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

    return Rx.combineLatest2(
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
    );
  }

  Stream<List<TransactionModel>> getTransfersByWallet(String walletId) {
    final fromQuery = _buildQuery(fromWalletId: walletId);
    final toQuery = _buildQuery(toWalletId: walletId);

    return Rx.combineLatest2(
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
    );
  }

  // ======================= Add Transfer =======================
  Future<TransactionModel> addTransfer(TransactionModel transfer) async {
    if (transfer.fromWalletId == null || transfer.toWalletId == null) {
      throw Exception('Wallet ID can not be null');
    }
    if (transfer.fromWalletId == transfer.toWalletId) {
      throw Exception('From Wallet and To Wallet can not be shame');
    }

    final docRef = transfersRef.doc();
    final newTransfer = transfer.copyWith(id: docRef.id);

    final batch = _db.batch();

    final fromWallet = await _walletService.getWalletById(
      transfer.fromWalletId!,
    );
    final toWallet = await _walletService.getWalletById(transfer.toWalletId!);

    if (fromWallet != null) {
      _walletService.updateWalletBatch(
        batch,
        fromWallet.copyWith(
          currentBalance: fromWallet.currentBalance - transfer.amount,
        ),
      );
    }
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

    return newTransfer;
  }

  // ======================= Update Transfer =======================
  Future<TransactionModel> updateTransfer(
    TransactionModel oldData,
    TransactionModel newData,
  ) async {
    final batch = _db.batch();

    final oldFromWallet =
        oldData.fromWalletId != null
            ? await _walletService.getWalletById(oldData.fromWalletId!)
            : null;
    final oldToWallet =
        oldData.toWalletId != null
            ? await _walletService.getWalletById(oldData.toWalletId!)
            : null;

    final walletBalances = <String, double>{};

    if (oldFromWallet != null) {
      walletBalances[oldFromWallet.id] =
          oldFromWallet.currentBalance + oldData.amount;
    }
    if (oldToWallet != null) {
      walletBalances[oldToWallet.id] =
          oldToWallet.currentBalance - oldData.amount;
    }

    final newFromWallet = await _walletService.getWalletById(
      newData.fromWalletId!,
    );
    final newToWallet = await _walletService.getWalletById(newData.toWalletId!);

    if (newFromWallet == null || newToWallet == null) {
      throw Exception("New wallet not found");
    }

    walletBalances[newData.fromWalletId!] =
        (walletBalances[newData.fromWalletId!] ??
            newFromWallet.currentBalance) -
        newData.amount;
    walletBalances[newData.toWalletId!] =
        (walletBalances[newData.toWalletId!] ?? newToWallet.currentBalance) +
        newData.amount;

    for (final entry in walletBalances.entries) {
      final walletRef = _db.collection('wallets').doc(entry.key);
      batch.update(walletRef, {'currentBalance': entry.value});
    }

    final transferRef = _db.collection('transactions').doc(oldData.id);
    batch.update(transferRef, newData.toMap());

    await batch.commit();
    return newData;
  }

  // ======================= Delete Transfer =======================
  Future<void> deleteTransfer(String id) async {
    final doc = await transfersRef.doc(id).get();
    if (!doc.exists) return;

    final tx = TransactionModel.fromFirestore(doc);

    final batch = _db.batch();

    if (tx.fromWalletId != null) {
      final fromWallet = await _walletService.getWalletById(tx.fromWalletId!);
      if (fromWallet != null) {
        _walletService.updateWalletBatch(
          batch,
          fromWallet.copyWith(
            currentBalance: fromWallet.currentBalance + tx.amount,
          ),
        );
      }
    }

    if (tx.toWalletId != null) {
      final toWallet = await _walletService.getWalletById(tx.toWalletId!);
      if (toWallet != null) {
        _walletService.updateWalletBatch(
          batch,
          toWallet.copyWith(
            currentBalance: toWallet.currentBalance - tx.amount,
          ),
        );
      }
    }

    batch.delete(transfersRef.doc(id));
    await batch.commit();
  }

  // ======================= Get Transfer By ID =======================
  Future<TransactionModel?> getTransferById(String id) async {
    final doc = await transfersRef.doc(id).get();
    if (!doc.exists) return null;
    return TransactionModel.fromFirestore(doc);
  }
}
