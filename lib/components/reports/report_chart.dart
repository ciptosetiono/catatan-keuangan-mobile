import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ReportChart extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const ReportChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: Colors.blue,
            spots:
                transactions.asMap().entries.map((e) {
                  return FlSpot(
                    e.key.toDouble(),
                    (e.value["type"] == "income"
                            ? e.value["amount"]
                            : -e.value["amount"])
                        .toDouble(),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
