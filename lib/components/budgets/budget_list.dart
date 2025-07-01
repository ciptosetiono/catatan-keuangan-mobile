import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../services/budget_service.dart';
import '../../services/transaction_service.dart';
import 'budget_item.dart';

class BudgetList extends StatelessWidget {
  final DateTime selectedMonth;
  final String selectedCategoryId;
  final List<Category> categories;
  final String userId;

  const BudgetList({
    super.key,
    required this.selectedMonth,
    required this.selectedCategoryId,
    required this.categories,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Budget>>(
      stream: BudgetService().getBudgets(selectedMonth, selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("Terjadi kesalahan saat memuat data."),
          );
        }

        final budgets = snapshot.data ?? [];

        final totalBudget = budgets.fold<double>(
          0.0,
          (sum, b) => sum + b.amount,
        );

        if (budgets.isEmpty) {
          return const Center(child: Text("Belum ada anggaran."));
        }

        return FutureBuilder<double>(
          future: TransactionService().getTotalSpentByMonth(selectedMonth),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalUsed = snapshot.data ?? 0;
            final remaining = totalBudget - totalUsed;
            final percentUsed =
                totalBudget == 0
                    ? 0.0
                    : (totalUsed / totalBudget).clamp(0.0, 1.0);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Anggaran',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id',
                                  symbol: 'Rp',
                                ).format(totalBudget),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Total Pengeluaran: ${NumberFormat.currency(locale: 'id', symbol: 'Rp').format(totalUsed)}',
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: percentUsed,
                                backgroundColor: Colors.grey[300],
                                color: Colors.redAccent,
                                minHeight: 8,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sisa: ${NumberFormat.currency(locale: 'id', symbol: 'Rp').format(remaining)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  // Ganti Expanded -> Flexible
                  child: ListView.builder(
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      final category = categories.firstWhere(
                        (c) => c.id == budget.categoryId,
                        orElse:
                            () => Category(
                              id: budget.categoryId,
                              name: budget.categoryId,
                              type: 'expense',
                              userId: userId,
                            ),
                      );

                      return BudgetItem(
                        budget: budget,
                        category: category,
                        selectedMonth: selectedMonth,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
