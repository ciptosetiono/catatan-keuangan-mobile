// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/models/category_model.dart';
import 'package:money_note/services/firebase/wallet_service.dart';
import 'package:money_note/services/firebase/category_service.dart';
import 'package:money_note/components/transactions/transaction_bottomsheet_menu.dart';
import 'package:money_note/components/transactions/transaction_detail_tile.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _transaction;
  String walletName = '-';
  String categoryName = '-';

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    loadNames();
  }

  Future<void> loadNames() async {
    final wallet = await getWalletName(widget.transaction.walletId);
    final category = await getCategoryName(widget.transaction.categoryId);

    setState(() {
      walletName = wallet;
      categoryName = category;
    });
  }

  Future<String> getWalletName(String? walletId) async {
    if (walletId == null || walletId.isEmpty) return '-';

    final Wallet? wallet = await WalletService().getWalletById(walletId);

    if (wallet == null || wallet.id.isEmpty) return '-';
    return wallet.name.isNotEmpty ? wallet.name : '-';
  }

  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null) return '-';
    final Category? category = await CategoryService().getCategoryById(
      categoryId,
    );
    if (category == null || category.id.isEmpty) return '-';
    return category.name.isNotEmpty ? category.name : '-';
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(decimalDigits: 0, symbol: '');
    final formatDate = DateFormat('EEEE, d MMMM yyyy');

    final isIncome = _transaction?.type == 'income';

    // ignore: deprecated_member_use
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan icon dan jumlah
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isIncome ? Colors.green : Colors.red,
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatCurrency.format(_transaction?.amount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        isIncome ? 'Income' : 'Expense',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TransactionDetailTile(
              icon: Icons.calendar_today,
              label: 'Date',
              value: formatDate.format(_transaction?.date ?? DateTime.now()),
            ),
            TransactionDetailTile(
              icon: Icons.account_balance_wallet,
              label: 'Wallet',
              value: walletName,
            ),
            TransactionDetailTile(
              icon: Icons.category,
              label: 'Category',
              value: categoryName,
            ),
            TransactionDetailTile(
              icon: Icons.note,
              label: 'Note',
              value: _transaction?.title ?? '-',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.more_vert),
        onPressed:
            () => showTransactionBottomsheetMenu(
              context: context,
              transaction: _transaction!,
              onUpdated: (updatedTransaction) {
                debugPrint(
                  "Triggering onSaved callback from TransactioDetailScreen",
                );
                setState(() {
                  _transaction = updatedTransaction;
                });
                loadNames(); // refresh wallet & category
                Navigator.pop(context, 'updated');
              },
              onDeleted: () {
                Navigator.pop(context, 'deleted');
              },
            ),
      ),
    );
  }
}
