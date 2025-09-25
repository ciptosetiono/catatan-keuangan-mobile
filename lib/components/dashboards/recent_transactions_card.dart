import 'package:flutter/material.dart';

import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/transaction_model.dart';

import 'package:money_note/services/firebase/transaction_service.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService().getTransactionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final data = snapshot.data!;
        if (data.isEmpty) return const Text('there is not any transaction.');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Transactions',
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
                child: const Text('Show all transactions'),
              ),
            ),
          ],
        );
      },
    );
  }
}
