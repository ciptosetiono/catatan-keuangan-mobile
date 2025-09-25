import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'wallet_service.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // ignore: unused_field
  final WalletService _walletService = WalletService();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  final CollectionReference<TransactionModel> _transactionsRef =
      FirebaseFirestore.instance
          .collection('transactions')
          .withConverter<TransactionModel>(
            fromFirestore: (snap, _) => TransactionModel.fromFirestore(snap),
            toFirestore: (tx, _) => tx.toMap(),
          );

  final _walletsRef = FirebaseFirestore.instance.collection('wallets');

  TransactionService() {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ======================= Core Query Builder =======================
  Query<TransactionModel> _buildQuery({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
    String orderByField = 'date',
    bool descending = true,
  }) {
    Query<TransactionModel> query = _transactionsRef.where(
      'userId',
      isEqualTo: userId,
    );

    if (fromDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }
    if (toDate != null) {
      query = query.where('date', isLessThan: Timestamp.fromDate(toDate));
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    } else {
      // filter khusus income atau expense, tipe transfer tidak diikutkan
      query = query.where('type', whereIn: ['income', 'expense']);
    }

    if (walletId != null) query = query.where('walletId', isEqualTo: walletId);
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (title != null) query = query.where('title', isEqualTo: title);

    return query.orderBy(orderByField, descending: descending);
  }

  // ======================= Streams =======================
  Stream<List<TransactionModel>> getTransactionsStream({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) {
    final query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      title: title,
    );

    return query
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<QuerySnapshot<TransactionModel>> getTransactionsPaginated({
    required int limit,
    DocumentSnapshot<TransactionModel>? startAfter,
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? title,
    String? walletId,
    String? categoryId,
  }) async {
    Query<TransactionModel> query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      title: title,
      walletId: walletId,
      categoryId: categoryId,
    );

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    return await query.get();
  }

  Stream<List<TransactionModel>> getTransactionsByWallet(String walletId) {
    return _buildQuery(
      walletId: walletId,
    ).snapshots().map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<DocumentSnapshot<T>> safeGetDoc<T>(DocumentReference<T> ref) async {
    var snap = await ref.get(const GetOptions(source: Source.cache));
    if (!snap.exists) {
      snap = await ref.get(const GetOptions(source: Source.server));
    }
    return snap;
  }

  // ======================= CRUD Operations (Batch Version) =======================

  Future<TransactionModel> addTransaction(Map<String, dynamic> data) async {
    if (userId == null) throw Exception("User not logged in");

    final docRef = _transactionsRef.doc();
    final txModel = TransactionModel.fromMap(
      data,
    ).copyWith(id: docRef.id, userId: userId!);

    final batch = _db.batch();

    // 🔹 Update wallet balance
    if (txModel.walletId != null) {
      final walletRef = _walletsRef.doc(txModel.walletId!);
      final walletSnap = await safeGetDoc(walletRef);

      if (walletSnap.exists) {
        final wallet = Wallet.fromMap(walletSnap.id, walletSnap.data()!);
        final newBalance =
            txModel.type == 'income'
                ? wallet.currentBalance + txModel.amount
                : wallet.currentBalance - txModel.amount;
        batch.update(
          walletRef,
          wallet.copyWith(currentBalance: newBalance).toMap(),
        );
      }
    }

    // 🔹 Simpan transaksi
    batch.set(docRef, txModel);
   print('transaction saved');
   Future.microtask(() async {
  try {
    await batch.commit();
  } catch (e) {
  }
});
    return txModel;
  }

 Future<TransactionModel> updateTransaction(
  String id,
  Map<String, dynamic> newData,
) async {
  if (userId == null) throw Exception("User not logged in");

  final docRef = _transactionsRef.doc(id);
  final trxSnap = await safeGetDoc(docRef);

  if (!trxSnap.exists) throw Exception("Transaction not found");

  final oldTx = trxSnap.data()!;
  final newTx = oldTx.copyWith(
    amount: (newData['amount'] ?? oldTx.amount).toDouble(),
    type: newData['type'] ?? oldTx.type,
    walletId: newData['walletId'] ?? oldTx.walletId,
    categoryId: newData['categoryId'] ?? oldTx.categoryId,
    date: newData['date'] ?? oldTx.date,
    title: newData['title'] ?? oldTx.title,
  );

  final batch = _db.batch();

  // 🔹 Revert saldo lama
  if (oldTx.walletId != null) {
    final oldWalletRef = _walletsRef.doc(oldTx.walletId!);
    batch.update(
      oldWalletRef,
      {
        "currentBalance": FieldValue.increment(
          oldTx.type == 'income' ? -oldTx.amount : oldTx.amount,
        ),
      },
    );
  }

  // 🔹 Apply saldo baru
  if (newTx.walletId != null) {
    final newWalletRef = _walletsRef.doc(newTx.walletId!);
    batch.update(
      newWalletRef,
      {
        "currentBalance": FieldValue.increment(
          newTx.type == 'income' ? newTx.amount : -newTx.amount,
        ),
      },
    );
  }

  // 🔹 Update transaksi
  batch.update(docRef, newTx.toMap());

   Future.microtask(() async {
  try {
    await batch.commit();
  } catch (e) {
  }
});


  // langsung return ke UI agar bekerja saat offline
  return newTx;
}


  Future<void> deleteTransaction(TransactionModel transaction) async {
    if (userId == null) throw Exception("User not logged in");

    final docRef = _transactionsRef.doc(transaction.id);
    final trxSnap = await safeGetDoc(docRef);

    if (!trxSnap.exists) throw Exception("Transaction not found");

    final txModel = trxSnap.data()!;
    final batch = _db.batch();

    // 🔹 Kembalikan saldo
    if (txModel.walletId != null) {
      final walletRef = _walletsRef.doc(txModel.walletId!);
      final walletSnap = await safeGetDoc(walletRef);

      if (walletSnap.exists) {
        final wallet = Wallet.fromMap(walletSnap.id, walletSnap.data()!);
        final revertedBalance =
            txModel.type == 'income'
                ? wallet.currentBalance - txModel.amount
                : wallet.currentBalance + txModel.amount;

        batch.update(
          walletRef,
          wallet.copyWith(currentBalance: revertedBalance).toMap(),
        );
      }
    }

    // 🔹 Hapus transaksi
    batch.delete(docRef);

Future.microtask(() async {
  try {
    await batch.commit();
  } catch (e) {
  }
});

  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final doc = await _transactionsRef
        .doc(id)
        .get(GetOptions(source: Source.cache));
    if (doc.exists) return doc.data();
    final serverDoc = await _transactionsRef
        .doc(id)
        .get(GetOptions(source: Source.server));
    if (serverDoc.exists) return serverDoc.data();
    return null;
  }

  // ======================= Aggregations =======================
  Future<double> getTotalSpentByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final query = _buildQuery(fromDate: from, toDate: to, type: 'expense');
    var snapshot = await query.get(GetOptions(source: Source.cache));

    if (snapshot.docs.isEmpty) {
      snapshot = await query.get(const GetOptions(source: Source.server));
    }

    return snapshot.docs.fold<double>(
      0.0,
      // ignore: avoid_types_as_parameter_names
      (sum, doc) => sum + (doc['amount'] as num).toDouble(),
    );
  }

  Future<double> getTotalIncomeByMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final query = _buildQuery(fromDate: from, toDate: to, type: 'income');
    var snapshot = await query.get(GetOptions(source: Source.cache));
    if (snapshot.docs.isEmpty) {
      snapshot = await query.get(const GetOptions(source: Source.server));
    }
    return snapshot.docs.fold<double>(
      0.0,
      // ignore: avoid_types_as_parameter_names
      (sum, doc) => sum + (doc['amount'] as num).toDouble(),
    );
  }

 Future<Map<String, double>> getTotalSpentByCategories({
  required List<String> categoryIds,
  required DateTime month,
}) async {
  print('categoryIds: $categoryIds');

  final from = DateTime(month.year, month.month);
  final to = DateTime(month.year, month.month + 1);

  // 🔎 Fetch all expense transactions for the given month (one query only)
  final query = _buildQuery(
    fromDate: from,
    toDate: to,
    type: 'expense',
  );

  QuerySnapshot snapshot;

  try {
    snapshot = await query.get(const GetOptions(source: Source.cache));
    if (snapshot.docs.isEmpty) {
      // fallback to server if cache empty
      snapshot = await query.get(const GetOptions(source: Source.server));
    }
  } catch (e) {
    print("Error fetching transactions: $e");
    return {};
  }

  // 🔄 Group by categoryId locally
  Map<String, double> totals = {};
  for (var doc in snapshot.docs) {
    final categoryId = doc['categoryId'] as String?;
    final amount = (doc['amount'] as num).toDouble();

    if (categoryId != null && categoryIds.contains(categoryId)) {
      totals[categoryId] = (totals[categoryId] ?? 0) + amount;
    }
  }

  // 🛠️ Ensure all requested categories exist in the map (with 0.0 if no data)
  for (var id in categoryIds) {
    totals[id] = totals[id] ?? 0.0;
  }

  return totals;
}


  Stream<Map<String, num>> getSummary({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? walletId,
    String? categoryId,
    String? title,
  }) async* {
    // ambil snapshot realtime dari query Firestore
    final query = _buildQuery(
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      title: title,
    );

    await for (final snapshot in query.snapshots(
      includeMetadataChanges: true,
    )) {
      num income = 0;
      num expense = 0;

      for (var doc in snapshot.docs) {
        final trx = doc.data();
        // ignore: unnecessary_null_comparison
        if (trx == null) continue;

        if (trx.type == 'income') {
          income += trx.amount;
        } else if (trx.type == 'expense') {
          expense += trx.amount;
        }
      }

      yield {'income': income, 'expense': expense, 'balance': income - expense};
    }
  }
}
