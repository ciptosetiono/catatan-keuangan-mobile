import 'package:flutter/material.dart';
import 'package:money_note/components/reports/report_list_item.dart';
import 'package:money_note/utils/currency_formatter.dart';

class ReportList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedData;
  final String groupBy;
  const ReportList({
    super.key,
    required this.groupedData,
    required this.groupBy,
  });

  @override
  Widget build(BuildContext context) {
    final keys = groupedData.keys.toList()..sort();
    final CurrencyFormatter currencyFormatter = CurrencyFormatter();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final key = keys[i];
        final items = groupedData[key]!;

        final totalIncome = items
            .where((tx) => tx["type"] == "income")
            .fold(0.0, (sum, tx) => sum + (tx["amount"] as num).toDouble());

        final totalExpense = items
            .where((tx) => tx["type"] == "expense")
            .fold(0.0, (sum, tx) => sum + (tx["amount"] as num).toDouble());

        final totalBalance = totalIncome - totalExpense;

        return ReportListItem(
          dataKey: key,
          title: key,
          subtitle:
              "Income: ${currencyFormatter.encode(totalIncome)} | "
              "Expense: ${currencyFormatter.encode(totalExpense)} | "
              "Balance: ${currencyFormatter.encode(totalBalance)}",
          items: items,
        );
      },
    );
  }
}
