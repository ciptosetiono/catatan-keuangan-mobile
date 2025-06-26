import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionSummaryCard extends StatelessWidget {
  final num income;
  final num expense;
  final num balance;

  const TransactionSummaryCard({
    Key? key,
    required this.income,
    required this.expense,
    required this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem(
              label: 'Pemasukan',
              value: income,
              color: Colors.green,
            ),
            _buildSummaryItem(
              label: 'Pengeluaran',
              value: expense,
              color: Colors.red,
            ),
            _buildSummaryItem(
              label: 'Saldo',
              value: balance,
              color: Colors.blue,
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
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: 'id', symbol: 'Rp').format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
