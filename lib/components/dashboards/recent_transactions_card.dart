import 'package:flutter/material.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/sqlite/transaction_service.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = CurrencyFormatter();

    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService().getTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('There are no recent transactions.'));
        }

        final data = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            /// ✅ show only 5 latest transactions
            ...data.take(5).map((trx) {
              final isIncome = trx.type == 'income';
              final iconColor = isIncome ? Colors.green : Colors.red;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: iconColor,
                ),
                title: Text(trx.title),
                subtitle: Text(
                  '${trx.date.day}/${trx.date.month}/${trx.date.year}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                /// ✅ Use FutureBuilder for async currency display
                trailing: FutureBuilder<String>(
                  future: currencyFormatter.encode(trx.amount),
                  builder: (context, snapshot) {
                    final amountText = snapshot.data ?? '...';
                    return Text(
                      amountText,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
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
