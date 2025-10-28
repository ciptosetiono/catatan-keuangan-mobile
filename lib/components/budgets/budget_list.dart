import 'package:flutter/material.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/budget_model.dart';
import 'package:money_note/models/category_model.dart';
import 'package:money_note/services/sqlite/budget_service.dart';
import 'package:money_note/services/sqlite/transaction_service.dart';
import 'package:money_note/components/budgets/budget_item.dart';

class BudgetList extends StatelessWidget {
  final DateTime selectedMonth;
  final List<Category> categories;

  const BudgetList({
    super.key,
    required this.selectedMonth,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = CurrencyFormatter();

    return StreamBuilder<List<Budget>>(
      stream: BudgetService().getBudgetStream(month: selectedMonth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Oops, something went wrong!"));
        }

        final allBudgets = snapshot.data ?? [];
        final categoryIds = categories.map((c) => c.id).toSet();
        final filteredBudgets =
            allBudgets
                .where((b) => categoryIds.contains(b.categoryId))
                .toList();

        if (filteredBudgets.isEmpty) {
          return const Center(child: Text("No budgets found."));
        }

        final filteredCategoryIds =
            filteredBudgets.map((b) => b.categoryId).toSet().toList();

        return FutureBuilder<Map<String, double>>(
          future: TransactionService().getTotalSpentByCategories(
            categoryIds: filteredCategoryIds,
            month: selectedMonth,
          ),
          builder: (context, trxSnapshot) {
            if (trxSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final usedMap = trxSnapshot.data ?? {};
            final totalBudget = filteredBudgets.fold<double>(
              0.0,
              (sum, b) => sum + b.amount,
            );
            final totalUsed = usedMap.values.fold<double>(
              0.0,
              (sum, used) => sum + used,
            );
            final remaining = totalBudget - totalUsed;
            final percentUsed =
                totalBudget == 0
                    ? 0.0
                    : (totalUsed / totalBudget).clamp(0.0, 1.0);

            final categoryMap = {for (var c in categories) c.id: c};

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Budget',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),

                          /// ✅ Async currency formatting
                          FutureBuilder<String>(
                            future: currencyFormatter.encode(totalBudget),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Loading...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FutureBuilder<String>(
                                future: currencyFormatter.encode(totalUsed),
                                builder: (context, snapshot) {
                                  return Text(
                                    'Total Expense: ${snapshot.data ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  );
                                },
                              ),
                              FutureBuilder<String>(
                                future: currencyFormatter.encode(remaining),
                                builder: (context, snapshot) {
                                  return Text(
                                    'Remaining: ${snapshot.data ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentUsed,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.redAccent.shade400,
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredBudgets.length,
                    itemBuilder: (context, index) {
                      final budget = filteredBudgets[index];
                      final category =
                          categoryMap[budget.categoryId] ??
                          Category(
                            id: budget.categoryId,
                            name: budget.categoryId,
                            type: 'expense',
                            userId: budget.userId,
                          );
                      final usedAmount = usedMap[budget.categoryId] ?? 0.0;

                      return BudgetItem(
                        budget: budget,
                        category: category,
                        selectedMonth: selectedMonth,
                        usedAmount: usedAmount,
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
