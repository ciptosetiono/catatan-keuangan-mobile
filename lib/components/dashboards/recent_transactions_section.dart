// lib/components/dashboard/recent_transactions_section.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/sqlite/transaction_service.dart';
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
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

            return Column(
              children:
                  latest.map((trx) {
                    final isIncome = trx.type == 'income';
                    final color = isIncome ? Colors.green : Colors.red;
                    final icon =
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward;

                    return InkWell(
                      onTap: () => onTapItem?.call(trx),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const SizedBox(width: 12),

                            // judul + tanggal
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trx.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(trx.date),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // jumlah
                            Text(
                              (isIncome ? '+ ' : '- ') +
                                  CurrencyFormatter().encode(trx.amount),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
