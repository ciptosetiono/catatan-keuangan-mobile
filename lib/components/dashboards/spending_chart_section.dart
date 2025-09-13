// lib/components/dashboard/spending_chart_section.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/category_model.dart';

import 'package:money_note/services/category_service.dart';
import 'package:money_note/services/transaction_service.dart';
import 'package:money_note/screens/categories/category_detail_screen.dart';

import 'section_title.dart';

class SpendingChartSection extends StatefulWidget {
  final VoidCallback? onSeeAll;

  const SpendingChartSection({super.key, this.onSeeAll});

  @override
  State<SpendingChartSection> createState() => _SpendingChartSectionState();
}

class _SpendingChartSectionState extends State<SpendingChartSection> {
  final _categoryService = CategoryService();
  final _transactionService = TransactionService();

  late final Future<List<_CategoryTotal>> _chartDataFuture;
  // ignore: prefer_final_fields
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _loadChartData();
  }

  Future<List<_CategoryTotal>> _loadChartData() async {
    // 1) fetch all expense categories
    final categories =
        await _categoryService.getCategoryStream(type: 'expense').first;
    if (categories.isEmpty) return [];

    // 2) fetch totals per category
    final totals = await _transactionService.getTotalSpentByCategories(
      categoryIds: categories.map((c) => c.id).toList(),
      month: _selectedMonth,
    );

    // 3) build list of nonzero entries
    return categories
        .where((c) => (totals[c.id] ?? 0) > 0)
        .map((c) => _CategoryTotal(c, totals[c.id] ?? 0))
        .toList();
  }

  Color _getColor(String name) {
    final idx = name.hashCode.abs() % Colors.primaries.length;
    return Colors.primaries[idx].shade400;
  }

  void _openCategoryDetail(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Expenses By Category', onSeeAll: widget.onSeeAll),
        const SizedBox(height: 12),
        FutureBuilder<List<_CategoryTotal>>(
          future: _chartDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to get categories data!',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            final data = snapshot.data!;
            if (data.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('There is no spent by category on this month!.'),
              );
            }

            final totalAll = data.fold<double>(0, (sum, e) => sum + e.amount);

            return Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections:
                          data.map((entry) {
                            final percent =
                                totalAll == 0
                                    ? 0.0
                                    : entry.amount / totalAll * 100;
                            return PieChartSectionData(
                              value: entry.amount,
                              title: '${percent.toStringAsFixed(1)}%',
                              color: _getColor(entry.category.name),
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...data.map((entry) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      dense: true, // makes the tile more compact
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ), // reduce padding
                      leading: CircleAvatar(
                        backgroundColor: _getColor(
                          entry.category.name,
                          // ignore: deprecated_member_use
                        ).withOpacity(0.3),
                      ),
                      title: Text(entry.category.name),
                      trailing: Text(
                        CurrencyFormatter().encode(entry.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _openCategoryDetail(entry.category),
                    ),
                  );
                  // ignore: unnecessary_to_list_in_spreads
                }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTotal {
  final Category category;
  final double amount;
  _CategoryTotal(this.category, this.amount);
}
