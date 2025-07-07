// lib/components/dashboard/recent_transactions_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/transaction_model.dart';
import '../../../services/transaction_service.dart';
import '../../../utils/currency_formatter.dart';
import 'section_title.dart';

class RecentTransactionsSection extends StatelessWidget {
  final TransactionService _transactionService = TransactionService();
  final VoidCallback? onSeeAll;

  RecentTransactionsSection({super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Last Transactions', onSeeAll: onSeeAll),
        const SizedBox(height: 8),
        StreamBuilder<List<TransactionModel>>(
          stream: _transactionService.getTransactionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading transactions: \${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final transactions = snapshot.data ?? [];
            if (transactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('There is no transaction.'),
              );
            }

            final latest = transactions.take(5).toList();

            return Column(
              children:
                  latest.map((trx) {
                    final isIncome = trx.type == 'income';
                    final color = isIncome ? Colors.green : Colors.red;
                    final icon =
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(trx.title),
                      subtitle: Text(DateFormat.yMMMMd().format(trx.date)),
                      trailing: Text(
                        (isIncome ? '+ ' : '- ') +
                            CurrencyFormatter().encode(trx.amount),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }
}
