import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/transaction_model.dart';

class TransferService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference
  transfersRef = FirebaseFirestore.instance.collection(
    'transactions',
  ); //data transfer disimpan di collection transactions dengan tipe 'transfer'
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Stream khusus untuk data transfer
  Stream<List<TransactionModel>> getTransfers({
    String? fromWalletId,
    String? toWalletId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    // Siapkan range tanggal jika ada
    final Timestamp? startTimestamp =
        fromDate != null ? Timestamp.fromDate(fromDate) : null;
    final Timestamp? endTimestamp =
        toDate != null ? Timestamp.fromDate(toDate) : null;

    // Query untuk fromWalletId
    Query fromQuery = transfersRef
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'transfer');

    if (fromWalletId != null) {
      fromQuery = fromQuery.where('fromWalletId', isEqualTo: fromWalletId);
    }

    if (startTimestamp != null && endTimestamp != null) {
      fromQuery = fromQuery
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp);
    }

    // Query untuk toWalletId
    Query toQuery = transfersRef
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'transfer');

    if (toWalletId != null) {
      toQuery = toQuery.where('toWalletId', isEqualTo: toWalletId);
    }

    if (startTimestamp != null && endTimestamp != null) {
      toQuery = toQuery
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp);
    }

    return Rx.combineLatest2(fromQuery.snapshots(), toQuery.snapshots(), (
      QuerySnapshot fromSnap,
      QuerySnapshot toSnap,
    ) {
      final allDocsMap = <String, DocumentSnapshot>{};

      for (final doc in fromSnap.docs) {
        allDocsMap[doc.id] = doc;
      }
      for (final doc in toSnap.docs) {
        allDocsMap[doc.id] =
            doc; // Akan overwrite duplikat dengan doc.id yang sama
      }

      final allDocs = allDocsMap.values.toList();
      allDocs.sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA); // descending
      });
      return allDocs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<TransactionModel>> getTransfersByWallet({
    required String walletId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final Timestamp? startTimestamp =
        fromDate != null ? Timestamp.fromDate(fromDate) : null;
    final Timestamp? endTimestamp =
        toDate != null ? Timestamp.fromDate(toDate) : null;

    // Query dasar untuk dari wallet
    Query fromQuery = transfersRef
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'transfer')
        .where('fromWalletId', isEqualTo: walletId);

    // Query dasar untuk ke wallet
    Query toQuery = transfersRef
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'transfer')
        .where('toWalletId', isEqualTo: walletId);

    // Tambahkan filter tanggal jika ada
    if (startTimestamp != null && endTimestamp != null) {
      fromQuery = fromQuery
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp);
      toQuery = toQuery
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp);
    }

    // Gabungkan dua query menggunakan Rx.combineLatest2
    return Rx.combineLatest2(fromQuery.snapshots(), toQuery.snapshots(), (
      QuerySnapshot fromSnap,
      QuerySnapshot toSnap,
    ) {
      final Map<String, DocumentSnapshot> allDocsMap = {};

      // Masukkan semua dokumen dari query 'from'
      for (final doc in fromSnap.docs) {
        allDocsMap[doc.id] = doc;
      }

      // Masukkan semua dokumen dari query 'to', overwrite jika duplikat
      for (final doc in toSnap.docs) {
        allDocsMap[doc.id] = doc;
      }

      // Konversi ke list, urutkan descending berdasarkan tanggal
      final allDocs = allDocsMap.values.toList();
      allDocs.sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA);
      });

      return allDocs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addTransfer(TransactionModel transfer) async {
    if (transfer.fromWalletId == null || transfer.toWalletId == null) {
      throw Exception('Wallet ID could not be null');
    }

    if (transfer.fromWalletId == transfer.toWalletId) {
      throw Exception('From Wallet and To Wallet cannot be the same');
    }

    final fromWalletRef = _db.collection('wallets').doc(transfer.fromWalletId!);

    final toWalletRef = _db.collection('wallets').doc(transfer.toWalletId!);
    final newTransferRef = transfersRef.doc(); // Buat ID baru

    await _db.runTransaction((tx) async {
      // Tambahkan transaksi baru
      tx.set(newTransferRef, transfer.copyWith(id: newTransferRef.id).toMap());

      // Kurangi saldo wallet asal
      tx.update(fromWalletRef, {
        'currentBalance': FieldValue.increment(-transfer.amount.toInt()),
      });

      // Tambah saldo wallet tujuan
      tx.update(toWalletRef, {
        'currentBalance': FieldValue.increment(transfer.amount.toInt()),
      });
    });
  }

  Future<void> updateTransfer(
    TransactionModel oldData,
    TransactionModel newData,
  ) async {
    if (newData.fromWalletId == null || newData.toWalletId == null) {
      throw Exception('Wallet ID tidak boleh null');
    }

    if (newData.fromWalletId == newData.toWalletId) {
      throw Exception('Wallet asal dan tujuan tidak boleh sama');
    }

    final oldFromRef = _db.collection('wallets').doc(oldData.fromWalletId!);
    final oldToRef = _db.collection('wallets').doc(oldData.toWalletId!);
    final newFromRef = _db.collection('wallets').doc(newData.fromWalletId!);
    final newToRef = _db.collection('wallets').doc(newData.toWalletId!);
    final transfer = transfersRef.doc(oldData.id);

    await _db.runTransaction((tx) async {
      // Rollback saldo dari data lama
      tx.update(oldFromRef, {
        'currentBalance': FieldValue.increment(oldData.amount.toInt()),
      });
      tx.update(oldToRef, {
        'currentBalance': FieldValue.increment(-oldData.amount.toInt()),
      });

      // Update tranfer
      tx.update(transfer, newData.toMap());

      // Terapkan saldo baru
      tx.update(newFromRef, {
        'currentBalance': FieldValue.increment(-newData.amount.toInt()),
      });
      tx.update(newToRef, {
        'currentBalance': FieldValue.increment(newData.amount.toInt()),
      });
    });
  }

  Future<void> deleteTransfer(String id) async {
    final doc = await transfersRef.doc(id).get();

    if (!doc.exists) return;
    TransactionModel transfer = TransactionModel.fromFirestore(doc);

    if (transfer.fromWalletId == null || transfer.toWalletId == null) {
      throw Exception('Wallet ID tidak boleh null');
    }

    final fromWalletRef = _db.collection('wallets').doc(transfer.fromWalletId!);
    final toWalletRef = _db.collection('wallets').doc(transfer.toWalletId!);
    final transactionRef = transfersRef.doc(transfer.id);

    await _db.runTransaction((tx) async {
      // Hapus transaksi
      tx.delete(transactionRef);

      // Kembalikan saldo wallet asal
      tx.update(fromWalletRef, {
        'currentBalance': FieldValue.increment(transfer.amount.toInt()),
      });

      // Kurangi saldo wallet tujuan
      tx.update(toWalletRef, {
        'currentBalance': FieldValue.increment(-transfer.amount.toInt()),
      });
    });
  }
}
