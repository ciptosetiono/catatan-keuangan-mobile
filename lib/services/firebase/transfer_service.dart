import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';

class TransferService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference _transfersRef = FirebaseFirestore.instance
      .collection('transactions');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final _walletsRef = FirebaseFirestore.instance.collection('wallets');

  TransferService() {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
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

    return Rx.combineLatest2<
      QuerySnapshot<Map<String, dynamic>>,
      QuerySnapshot<Map<String, dynamic>>,
      List<TransactionModel>
    >(
      fromQuery.snapshots(includeMetadataChanges: true),
      toQuery.snapshots(includeMetadataChanges: true),
      (fromSnap, toSnap) {
        final allDocsMap = <String, DocumentSnapshot<Map<String, dynamic>>>{};

        for (final doc in fromSnap.docs) {
          allDocsMap[doc.id] = doc;
        }
        for (final doc in toSnap.docs) {
          allDocsMap[doc.id] = doc;
        }

        final allDocs =
            allDocsMap.values.toList()..sort((a, b) {
              final aDate = a.data()?['date'] as Timestamp?;
              final bDate = b.data()?['date'] as Timestamp?;
              return (bDate ?? Timestamp(0, 0)).compareTo(
                aDate ?? Timestamp(0, 0),
              );
            });

        return allDocs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();
      },
    );
  }

  Stream<List<TransactionModel>> getTransfersByWallet(String walletId) {
    final fromQuery = _buildQuery(fromWalletId: walletId);
    final toQuery = _buildQuery(toWalletId: walletId);

    return Rx.combineLatest2<
      QuerySnapshot<Map<String, dynamic>>,
      QuerySnapshot<Map<String, dynamic>>,
      List<TransactionModel>
    >(
      fromQuery.snapshots(includeMetadataChanges: true),
      toQuery.snapshots(includeMetadataChanges: true),
      (fromSnap, toSnap) {
        final allDocsMap = <String, DocumentSnapshot<Map<String, dynamic>>>{};

        for (final doc in fromSnap.docs) {
          allDocsMap[doc.id] = doc;
        }
        for (final doc in toSnap.docs) {
          allDocsMap[doc.id] = doc;
        }

        final allDocs =
            allDocsMap.values.toList()..sort((a, b) {
              final aDate = a.data()?['date'] as Timestamp?;
              final bDate = b.data()?['date'] as Timestamp?;
              return (bDate ?? Timestamp(0, 0)).compareTo(
                aDate ?? Timestamp(0, 0),
              );
            });

        return allDocs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();
      },
    );
  }

  Future<DocumentSnapshot<T>?> safeGetDoc<T>(DocumentReference<T> ref) async {
    try {
      final cacheDoc = await ref.get(const GetOptions(source: Source.cache));
      if (cacheDoc.exists) return cacheDoc;
    } catch (_) {}
    try {
      final serverDoc = await ref.get(const GetOptions(source: Source.server));
      if (serverDoc.exists) return serverDoc;
    } catch (_) {}
    return null;
  }

  // ======================= Add Transfer =======================
  Future<TransactionModel> addTransfer(TransactionModel transfer) async {
    if (transfer.fromWalletId == null || transfer.toWalletId == null) {
      throw Exception('Wallet ID can not be null');
    }
    if (transfer.fromWalletId == transfer.toWalletId) {
      throw Exception('From Wallet and To Wallet can not be same');
    }

    final docRef = _transfersRef.doc();
    final newTransfer = transfer.copyWith(id: docRef.id);

    final batch = _db.batch();

    final fromWalletDoc = await safeGetDoc(
      _walletsRef.doc(transfer.fromWalletId!),
    );
    final toWalletDoc = await safeGetDoc(_walletsRef.doc(transfer.toWalletId!));

    if (fromWalletDoc != null && fromWalletDoc.exists) {
      final fromWallet = Wallet.fromMap(
        fromWalletDoc.id,
        fromWalletDoc.data()!,
      );
      batch.update(fromWalletDoc.reference, {
        'currentBalance': fromWallet.currentBalance - transfer.amount,
      });
    }

    if (toWalletDoc != null && toWalletDoc.exists) {
      final toWallet = Wallet.fromMap(toWalletDoc.id, toWalletDoc.data()!);
      batch.update(toWalletDoc.reference, {
        'currentBalance': toWallet.currentBalance + transfer.amount,
      });
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
    final walletBalances = <String, double>{};

    // Rollback dari wallet lama
    if (oldData.fromWalletId != null) {
      final oldFromDoc = await safeGetDoc(
        _walletsRef.doc(oldData.fromWalletId!),
      );
      if (oldFromDoc != null && oldFromDoc.exists) {
        final oldFrom = Wallet.fromMap(oldFromDoc.id, oldFromDoc.data()!);
        walletBalances[oldFrom.id] = oldFrom.currentBalance + oldData.amount;
      }
    }

    if (oldData.toWalletId != null) {
      final oldToDoc = await safeGetDoc(_walletsRef.doc(oldData.toWalletId!));
      if (oldToDoc != null && oldToDoc.exists) {
        final oldTo = Wallet.fromMap(oldToDoc.id, oldToDoc.data()!);
        walletBalances[oldTo.id] = oldTo.currentBalance - oldData.amount;
      }
    }

    // Apply ke wallet baru
    final newFromDoc = await safeGetDoc(_walletsRef.doc(newData.fromWalletId!));
    final newToDoc = await safeGetDoc(_walletsRef.doc(newData.toWalletId!));

    if (newFromDoc == null || newToDoc == null) {
      throw Exception("New wallet not found (offline & belum cached)");
    }

    final newFrom = Wallet.fromMap(newFromDoc.id, newFromDoc.data()!);
    final newTo = Wallet.fromMap(newToDoc.id, newToDoc.data()!);

    walletBalances[newFrom.id] =
        (walletBalances[newFrom.id] ?? newFrom.currentBalance) - newData.amount;
    walletBalances[newTo.id] =
        (walletBalances[newTo.id] ?? newTo.currentBalance) + newData.amount;

    for (final entry in walletBalances.entries) {
      batch.update(_walletsRef.doc(entry.key), {'currentBalance': entry.value});
    }

    final transferRef = _transfersRef.doc(oldData.id);
    batch.update(transferRef, newData.toMap());

    await batch.commit();
    return newData;
  }

  // ======================= Delete Transfer =======================
  Future<void> deleteTransfer(String id) async {
    final doc = await safeGetDoc(_transfersRef.doc(id));
    if (doc == null || !doc.exists) return;

    final tx = TransactionModel.fromFirestore(doc);

    final batch = _db.batch();

    if (tx.fromWalletId != null) {
      final fromDoc = await safeGetDoc(_walletsRef.doc(tx.fromWalletId!));
      if (fromDoc != null && fromDoc.exists) {
        final fromWallet = Wallet.fromMap(fromDoc.id, fromDoc.data()!);
        batch.update(fromDoc.reference, {
          'currentBalance': fromWallet.currentBalance + tx.amount,
        });
      }
    }

    if (tx.toWalletId != null) {
      final toDoc = await safeGetDoc(_walletsRef.doc(tx.toWalletId!));
      if (toDoc != null && toDoc.exists) {
        final toWallet = Wallet.fromMap(toDoc.id, toDoc.data()!);
        batch.update(toDoc.reference, {
          'currentBalance': toWallet.currentBalance - tx.amount,
        });
      }
    }

    batch.delete(_transfersRef.doc(id));
    await batch.commit();
  }

  // ======================= Get Transfer By ID =======================
  Future<TransactionModel?> getTransferById(String id) async {
    final doc = await _transfersRef
        .doc(id)
        .get(GetOptions(source: Source.cache));
    if (doc.exists) return TransactionModel.fromFirestore(doc);
    final serverDoc = await _transfersRef
        .doc(id)
        .get(GetOptions(source: Source.server));
    if (serverDoc.exists) return TransactionModel.fromFirestore(serverDoc);
    return null;
  }
}
