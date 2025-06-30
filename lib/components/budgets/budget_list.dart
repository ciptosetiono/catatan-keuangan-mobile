import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../services/budget_service.dart';
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Anggaran:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp',
                    ).format(totalBudget),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
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
  }
}
