import 'package:flutter/material.dart';

import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/budget_model.dart';
import 'package:money_note/models/category_model.dart';

import 'package:money_note/services/budget_service.dart';
import 'package:money_note/services/transaction_service.dart';

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
    return StreamBuilder<List<Budget>>(
      stream: BudgetService().getBudgets(month: selectedMonth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("Oops, something went wrong! Please try again later."),
          );
        }

        final allBudgets = snapshot.data ?? [];

        // Filter budgets based on filtered categories
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

            // Map categoryId to Category for fast lookup
            final categoryMap = {for (var c in categories) c.id: c};

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Budget',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter().encode(totalBudget),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Total Expense: ${CurrencyFormatter().encode(totalUsed)}',
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
                            'Remaining Budget: ${CurrencyFormatter().encode(remaining)}',
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
