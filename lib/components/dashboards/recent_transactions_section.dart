// lib/components/dashboard/recent_transactions_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/transaction_service.dart';
import 'package:money_note/components/dashboards/section_title.dart';

class RecentTransactionsSection extends StatelessWidget {
  final TransactionService _transactionService = TransactionService();
  final VoidCallback? onSeeAll;
  final Function(TransactionModel trx)? onTapItem;

  RecentTransactionsSection({super.key, this.onSeeAll, this.onTapItem});

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
                  'Error loading transactions: ${snapshot.error}',
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

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: latest.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final trx = latest[index];
                final isIncome = trx.type == 'income';
                final color = isIncome ? Colors.green : Colors.red;
                final icon =
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward;

                return InkWell(
                  onTap: () => onTapItem?.call(trx),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.zero, // hilangkan padding default
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      trx.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMMd().format(trx.date),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      (isIncome ? '+ ' : '- ') +
                          CurrencyFormatter().encode(trx.amount),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
