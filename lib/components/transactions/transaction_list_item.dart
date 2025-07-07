import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final date = transaction.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              children: [
                Text(DateFormat('dd MMM yyyy').format(date)),
                /*
                if (transaction.walletId != null ||
                    transaction.categoryId != null)
                  Text(
                    '${transaction.walletId ?? ''}'
                    '${transaction.walletId != null && transaction.categoryId != null ? ' · ' : ''}'
                    '${transaction.categoryId ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  */
              ],
            ),
            trailing: Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp',
              ).format(transaction.amount),
              style: TextStyle(
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
