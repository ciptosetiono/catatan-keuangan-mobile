// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/transaction_model.dart';

import 'package:money_note/components/transactions/transaction_bottomsheet_menu.dart';
import 'package:money_note/components/transactions/transaction_detail_tile.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final void Function(TransactionModel)? onUpdated;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onUpdated,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
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
                      FutureBuilder<String>(
                        future: CurrencyFormatter().encode(
                          _transaction?.amount as num,
                        ),
                        builder: (context, snapshot) {
                          final balanceText = snapshot.data ?? '...';
                          return Text(
                            balanceText,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          );
                        },
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
              value: _transaction?.walletName ?? '-',
            ),
            TransactionDetailTile(
              icon: Icons.category,
              label: 'Category',
              value: _transaction?.categoryName ?? '-',
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
                setState(() {
                  _transaction = updatedTransaction;
                });
                widget.onUpdated?.call(updatedTransaction);
              },
              onDeleted: () {
                Navigator.pop(context, 'deleted');
              },
            ),
      ),
    );
  }
}
