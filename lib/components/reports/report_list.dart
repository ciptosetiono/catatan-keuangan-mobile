import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const ReportList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (ctx, i) {
        final tx = transactions[i];
        return ListTile(
          title: Text(
            "${tx["categoryName"] ?? "-"} - Rp ${tx["amount"].toString()}",
          ),
          subtitle: Text(
            "${DateFormat("yyyy-MM-dd").format(tx["date"].toDate())} | ${tx["accountName"] ?? "-"}",
          ),
          trailing: Text(
            tx["type"] == "income" ? "+" : "-",
            style: TextStyle(
              color: tx["type"] == "income" ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }
}
