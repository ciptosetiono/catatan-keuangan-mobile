import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionListItem extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = transaction.data()!;
    final isIncome = data['type'] == 'income';
    final date = (data['date'] as Timestamp).toDate();

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
              data['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd MMM yyyy').format(date)),
                if (data['account'] != null || data['category'] != null)
                  Text(
                    '${data['account'] ?? ''}'
                    '${data['account'] != null && data['category'] != null ? ' · ' : ''}'
                    '${data['category'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            trailing: Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp',
              ).format(data['amount']),
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
