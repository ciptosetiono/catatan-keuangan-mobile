import 'package:flutter/material.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class ReportListItem extends StatelessWidget {
  final String dataKey;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> items;

  const ReportListItem({
    super.key,
    required this.dataKey,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final CurrencyFormatter currencyFormatter = CurrencyFormatter();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(
          dataKey,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        children:
            items.map((tx) {
              final DateTime date =
                  tx["date"] is DateTime
                      ? tx["date"]
                      : DateTime.tryParse(tx["date"].toString()) ??
                          DateTime.now();

              return ListTile(
                title: Text(tx["title"] ?? "-"),
                subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                trailing: Text(
                  currencyFormatter.encode(tx["amount"] as num),
                  style: TextStyle(
                    color: tx["type"] == "income" ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
