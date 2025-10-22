// ignore_for_file: use_build_context_synchronously

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
  final void Function(TransactionModel)? onUpdated;
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

    return InkWell(
      onTap:
          () => handleTransactionTap(
            context: context,
            transaction: transaction,
            onUpdated: onUpdated,
            onDeleted: onDeleted,
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // income/expense indicator
            CircleAvatar(
              radius: 18,
              backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // title, category, and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // category name
                  if (transaction.categoryName != null &&
                      transaction.categoryName!.isNotEmpty)
                    Text(
                      transaction.categoryName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 2),

                  // transaction date
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // amount
            Text(
              CurrencyFormatter().encode(transaction.amount),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable handler for transaction actions (detail, edit, delete).
Future<void> handleTransactionTap({
  required BuildContext context,
  required TransactionModel transaction,
  final void Function(TransactionModel)? onUpdated,
  Function()? onDeleted,
}) async {
  final action = await showTransactionActionDialog(context);
  if (action == 'detail') {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TransactionDetailScreen(
              transaction: transaction,
              onUpdated: onUpdated,
            ),
      ),
    );

    if (result == 'deleted' && onDeleted != null) {
      onDeleted();
    }
  } else if (action == 'edit') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TransactionFormScreen(
              transactionId: transaction.id,
              existingData: transaction,
              onSaved: (updatedTransaction) {
                if (onUpdated != null) {
                  onUpdated(updatedTransaction);
                }
              },
            ),
      ),
    );
  } else if (action == 'delete') {
    final deleted = await showTransactionDeleteDialog(
      context: context,
      transaction: transaction,
    );

    if (deleted && onDeleted != null) {
      onDeleted();
    }
  }
}
