import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../models/category_model.dart';

import '../../services/transaction_service.dart';
import '../../services/wallet_service.dart';
import '../../services/category_service.dart';
import '../../screens/transactions/transaction_form_screen.dart';

import '../../../components/transactions/transaction_delete_dialog.dart';
import '../../../components/transactions/transaction_detail_tile.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _localTransaction;
  String walletName = '-';
  String categoryName = '-';
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _localTransaction = widget.transaction;
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

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(decimalDigits: 0, symbol: '');
    final formatDate = DateFormat('EEEE, d MMMM yyyy');

    final isIncome = _localTransaction?.type == 'income';

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanged); // kirim true jika ada perubahan
        return false; // cegah pop default
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Transaction'),
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => TransactionFormScreen(
                            transactionId: widget.transaction.id,
                            existingData: widget.transaction,
                          ),
                    ),
                  );

                  if (result == true) {
                    final updated = await TransactionService()
                        .getTransactionById(widget.transaction.id);
                    setState(() {
                      _localTransaction = updated;
                      _hasChanged = true;
                    });
                    await loadNames();
                  }
                } else if (value == 'delete') {
                  await showTransactionDeleteDialog(
                    context: context,
                    transactionId: widget.transaction.id,
                    onDeleted: () {
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                  );
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
            ),
          ],
        ),
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
                          formatCurrency.format(_localTransaction?.amount),
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
                value: formatDate.format(
                  _localTransaction?.date ?? DateTime.now(),
                ),
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
                value: _localTransaction?.title ?? '-',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> getWalletName(String? walletId) async {
    if (walletId == null) return '-';
    final Wallet wallet = await WalletService().getWalletById(walletId);
    if (wallet.id.isEmpty) return '-';
    return wallet.name.isNotEmpty ? wallet.name : '-';
  }

  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null) return '-';
    final Category category = await CategoryService().getCategoryById(
      categoryId,
    );
    if (category.id.isEmpty) return '-';
    return category.name.isNotEmpty ? category.name : '-';
  }
}
