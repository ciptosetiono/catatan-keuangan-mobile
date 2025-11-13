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

    final currencyFormatter = CurrencyFormatter();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final key = keys[i];
        final items = groupedData[key]!;

        final totalIncome = items
            .where((tx) => tx["type"] == "income")
            .fold<double>(0.0, (sum, tx) {
              final amount = tx["amount"];
              if (amount is num) return sum + amount.toDouble();
              if (amount is String) {
                return sum + (double.tryParse(amount) ?? 0.0);
              }
              return sum;
            });

        final totalExpense = items
            .where((tx) => tx["type"] == "expense")
            .fold<double>(0.0, (sum, tx) {
              final amount = tx["amount"];
              if (amount is num) return sum + amount.toDouble();
              if (amount is String) {
                return sum + (double.tryParse(amount) ?? 0.0);
              }
              return sum;
            });

        final totalBalance = totalIncome - totalExpense;

        // 🔹 Use FutureBuilder to handle async formatting
        return FutureBuilder<List<String>>(
          future: Future.wait([
            currencyFormatter.encode(totalIncome),
            currencyFormatter.encode(totalExpense),
            currencyFormatter.encode(totalBalance),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              // You can show shimmer or placeholder
              return const ListTile(
                title: Text("Loading..."),
                subtitle: Text("Calculating totals..."),
              );
            }

            final formatted = snapshot.data!;
            final incomeStr = formatted[0];
            final expenseStr = formatted[1];
            final balanceStr = formatted[2];

            return ReportListItem(
              dataKey: key,
              title: key,
              subtitle:
                  "Income: $incomeStr | Expense: $expenseStr | Balance: $balanceStr",
              items: items,
            );
          },
        );
      },
    );
  }
}
