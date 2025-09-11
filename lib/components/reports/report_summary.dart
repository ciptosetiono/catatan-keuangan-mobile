import 'package:flutter/material.dart';

class ReportSummary extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const ReportSummary({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            "Income: ${income.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.green),
          ),
          Text(
            "Expense: ${expense.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.red),
          ),
          Text(
            "Balance: ${balance.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
