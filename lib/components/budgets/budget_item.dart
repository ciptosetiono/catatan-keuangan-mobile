// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../screens/budgets/budget_detail_screen.dart';
import '../../../screens/budgets/budget_form_screen.dart';
import '../../../services/budget_service.dart';
import 'budget_delete_dialog.dart';

class BudgetItem extends StatelessWidget {
  final Budget budget;
  final Category category;
  final DateTime selectedMonth;
  final double usedAmount;

  const BudgetItem({
    super.key,
    required this.budget,
    required this.category,
    required this.selectedMonth,
    required this.usedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final double percentUsed = (usedAmount / budget.amount).clamp(0.0, 1.0);
    final bool isOverBudget = usedAmount > budget.amount;

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
            PopupMenuItem(value: 'detail', child: Text('Detail')),
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
            MaterialPageRoute(builder: (_) => BudgetFormScreen(budget: budget)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              LinearProgressIndicator(
                minHeight: 8,
                value: percentUsed,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Used: ${NumberFormat.currency(symbol: '').format(usedAmount)}'
                ' / ${NumberFormat.currency(symbol: '').format(budget.amount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverBudget ? Colors.red : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
