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
    final formattedAmount = CurrencyFormatter().encode(transaction.amount);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          () => handleTransactionTap(
            context: context,
            transaction: transaction,
            onUpdated: onUpdated,
            onDeleted: onDeleted,
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon indicator
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: isIncome ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green[600] : Colors.red[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Main transaction info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    transaction.title.isNotEmpty
                        ? transaction.title
                        : '(No note)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Category and Date row
                  Row(
                    children: [
                      if (transaction.categoryName != null &&
                          transaction.categoryName!.isNotEmpty)
                        Flexible(
                          child: Text(
                            transaction.categoryName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (transaction.categoryName != null &&
                          transaction.categoryName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              formattedAmount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green[600] : Colors.red[600],
              ),
              textAlign: TextAlign.right,
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
