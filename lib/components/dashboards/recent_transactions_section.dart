// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/sqlite/transaction_service.dart';
import 'package:money_note/components/dashboards/section_title.dart';
import 'package:money_note/screens/transactions/transaction_form_screen.dart';

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
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 56,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add your first transaction to get started.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionFormScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Add Transaction',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final latest = transactions.take(5).toList();

            return Column(
              children:
                  latest.map((trx) {
                    final isIncome = trx.type == 'income';
                    final color =
                        isIncome ? Colors.green[600]! : Colors.red[600]!;
                    final icon =
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward;
                    final formattedAmount = CurrencyFormatter().encode(
                      trx.amount,
                    );
                    final formattedDate = DateFormat(
                      'dd MMM yyyy',
                    ).format(trx.date);

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // icon indicator
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color:
                                    isIncome
                                        ? Colors.green[50]
                                        : Colors.red[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),

                            // main info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // title
                                  Text(
                                    trx.title.isNotEmpty
                                        ? trx.title
                                        : '(No note)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  // category + date
                                  Row(
                                    children: [
                                      if (trx.categoryName != null &&
                                          trx.categoryName!.isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            trx.categoryName!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blueGrey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      if (trx.categoryName != null &&
                                          trx.categoryName!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Text(
                                            '•',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // amount
                            Text(
                              formattedAmount,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
