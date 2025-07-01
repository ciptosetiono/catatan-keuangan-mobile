import 'package:flutter/material.dart';
import 'package:personal_finance_flutter/models/budget_model.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;
  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Budget Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${widget.budget.amount}'),
            const SizedBox(height: 8),
            Text('Category: ${widget.budget.categoryId}'),
            const SizedBox(height: 8),
            Text('Month: ${widget.budget.month.toLocal()}'),
          ],
        ),
      ),
    );
  }
}
