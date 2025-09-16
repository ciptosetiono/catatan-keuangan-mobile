import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ReportChart extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedData;
  final String groupBy;

  const ReportChart({
    super.key,
    required this.groupedData,
    required this.groupBy,
  });

  @override
  Widget build(BuildContext context) {
    return _buildBarChart();
  }

  /// 📊 Bar Chart (income & expense)
  Widget _buildBarChart() {
    final incomeByGroup = <String, double>{};
    final expenseByGroup = <String, double>{};

    groupedData.forEach((key, items) {
      final income = items
          .where((tx) => tx["type"] == "income")
          .fold(0.0, (sum, tx) => sum + (tx["amount"] as num).toDouble());

      final expense = items
          .where((tx) => tx["type"] == "expense")
          .fold(0.0, (sum, tx) => sum + (tx["amount"] as num).toDouble());

      incomeByGroup[key] = income;
      expenseByGroup[key] = expense;
    });

    final keys =
        incomeByGroup.keys.toSet().union(expenseByGroup.keys.toSet()).toList()
          ..sort();

    final barGroups = <BarChartGroupData>[];

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final income = incomeByGroup[key] ?? 0;
      final expense = expenseByGroup[key] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 6, // jarak antar batang income & expense
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 12,
              borderRadius: BorderRadius.circular(3),
            ),
            BarChartRodData(
              toY: expense,
              color: Colors.red,
              width: 12,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= keys.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  keys[index], // label bulan/tahun
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value >= 1000000) {
                  return Text(
                    '${(value / 1000000).toStringAsFixed(1)}M',
                    style: const TextStyle(fontSize: 10),
                  );
                } else if (value >= 1000) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
