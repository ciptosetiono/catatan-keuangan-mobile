import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/transaction_model.dart';

import 'package:money_note/screens/transactions/transaction_detail_screen.dart';
import 'package:money_note/screens/transactions/transaction_form_screen.dart';
import 'package:money_note/components/transactions/transaction_action_dialog.dart';
import 'package:money_note/components/transactions/transaction_delete_dialog.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onUpdated;
  final VoidCallback? onDeleted;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onUpdated,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final date = transaction.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap:
            () => handleTransactionTap(
              context: context,
              transaction: transaction,
              onUpdated: onUpdated,
              onDeleted: onDeleted,
            ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
            ),
            title: Text(
              transaction.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(DateFormat('dd MMM yyyy').format(date))],
            ),
            trailing: Text(
              CurrencyFormatter().encode(transaction.amount),
              style: TextStyle(
                fontSize: 14,
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable handler for transaction actions (detail, edit, delete).
Future<void> handleTransactionTap({
  required BuildContext context,
  required TransactionModel transaction,
  Function()? onUpdated,
  Function()? onDeleted,
}) async {
  final action = await showTransactionActionDialog(context);

  if (action == 'detail') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: transaction),
      ),
    );
  } else if (action == 'edit') {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TransactionFormScreen(
              transactionId: transaction.id,
              existingData: transaction,
            ),
      ),
    );

    if (updated == true && onUpdated != null) {
      onUpdated();
    }
  } else if (action == 'delete') {
    final deleted = await showTransactionDeleteDialog(
      context: context,
      transactionId: transaction.id,
    );

    if (deleted == true && onDeleted != null) {
      onDeleted();
    }
  }
}
