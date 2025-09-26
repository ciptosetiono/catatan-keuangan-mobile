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
    final keys =
        groupedData.keys.toList()..sort((a, b) {
          try {
            final da = DateTime.tryParse(a) ?? DateTime.now();
            final db = DateTime.tryParse(b) ?? DateTime.now();
            return da.compareTo(db);
          } catch (_) {
            return 0;
          }
        });

    final CurrencyFormatter currencyFormatter = CurrencyFormatter();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final key = keys[i];
        final items = groupedData[key]!;
        final totalIncome = items.where((tx) => tx["type"] == "income").fold(
          0.0,
          (sum, tx) {
            final amount = tx["amount"];
            double val = 0;
            if (amount is num) {
              val = amount.toDouble();
            } else if (amount is String) {
              val = double.tryParse(amount) ?? 0.0;
            }
            return sum + val;
          },
        );

        final totalExpense = items.where((tx) => tx["type"] == "expense").fold(
          0.0,
          (sum, tx) {
            final amount = tx["amount"];
            double val = 0;
            if (amount is num) {
              val = amount.toDouble();
            } else if (amount is String) {
              val = double.tryParse(amount) ?? 0.0;
            }
            return sum + val;
          },
        );

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
