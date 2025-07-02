import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../services/budget_service.dart';
import '../../../services/transaction_service.dart';
import '../../../screens/budgets/budget_detail_screen.dart';
import '../../../screens/budgets/budget_form_screen.dart';
import 'budget_delete_dialog.dart';

class BudgetItem extends StatelessWidget {
  final Budget budget;
  final Category category;
  final DateTime selectedMonth;

  const BudgetItem({
    super.key,
    required this.budget,
    required this.category,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: TransactionService().getTotalSpentByCategory(
        budget.categoryId,
        selectedMonth,
      ),
      builder: (context, snapshot) {
        final used = snapshot.data ?? 0.0;
        final percent = (used / budget.amount).clamp(0.0, 1.0);

        return InkWell(
          onTapDown: (details) async {
            final selected = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                details.globalPosition.dx,
                details.globalPosition.dy,
              ),
              items: const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            );

            if (selected == 'detail') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BudgetDetailScreen(budget: budget),
                ),
              );
            } else if (selected == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BudgetFormScreen(budget: budget),
                ),
              );
            } else if (selected == 'delete') {
              final confirm = await showBudgetDeleteDialog(context);
              if (confirm) {
                await BudgetService().deleteBudget(budget.id);
              }
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    minHeight: 8,
                    value: percent,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      used > budget.amount ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used: ${NumberFormat.currency(symbol: '').format(used)} / ${NumberFormat.currency(symbol: '').format(budget.amount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          used > budget.amount
                              ? Colors.red
                              : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
