import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../services/transaction_service.dart';
import '../../../utils/currency_formatter.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService().getTransactionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final data = snapshot.data!;
        if (data.isEmpty) return const Text('Belum ada transaksi.');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...data.take(5).map((trx) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  trx.type == 'income'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: trx.type == 'income' ? Colors.green : Colors.red,
                ),
                title: Text(trx.title),
                subtitle: Text(
                  '${trx.date.day}/${trx.date.month}/${trx.date.year}',
                ),
                trailing: Text(
                  CurrencyFormatter().encode(trx.amount),
                  style: TextStyle(
                    color: trx.type == 'income' ? Colors.green : Colors.red,
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/transactions');
                },
                child: const Text('Lihat Semua Transaksi'),
              ),
            ),
          ],
        );
      },
    );
  }
}
