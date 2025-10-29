import 'package:flutter/material.dart';
import 'package:money_note/utils/currency_formatter.dart';

class TransactionSummaryCard extends StatelessWidget {
  final num income;
  final num expense;
  final num balance;

  const TransactionSummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // lebih clean
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _buildSummaryItem(
                label: 'Income',
                value: income,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _buildSummaryItem(
                label: 'Expense',
                value: expense,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _buildSummaryItem(
                label: 'Balance',
                value: balance,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required num value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        FutureBuilder<String>(
          future: CurrencyFormatter().encode(value),
          builder: (context, snapshot) {
            final amountText = snapshot.data ?? '...';
            return Text(
              amountText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            );
          },
        ),
      ],
    );
  }
}
