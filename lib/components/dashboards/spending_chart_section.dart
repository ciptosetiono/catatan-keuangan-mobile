// lib/components/dashboard/spending_chart_section.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/category_model.dart';
import 'package:money_note/services/sqlite/category_service.dart';
import 'package:money_note/services/sqlite/transaction_service.dart';
import 'package:money_note/screens/transactions/transaction_form_screen.dart';
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

  Future<List<_CategoryTotal>>? _chartDataFuture;
  // ignore: prefer_final_fields
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _loadChartData();
  }

  Future<List<_CategoryTotal>> _loadChartData() async {
    final categories =
        await _categoryService.getCategoryStream(type: 'expense').first;

    if (categories.isEmpty) return [];

    final totals = await _transactionService.getTotalSpentByCategories(
      categoryIds: categories.map((c) => c.id).toList(),
      month: _selectedMonth,
    );

    return categories
        .where((c) => (totals[c.id] ?? 0) > 0)
        .map((c) => _CategoryTotal(c, totals[c.id] ?? 0))
        .toList();
  }

  Color _getColor(String name) {
    final idx = name.hashCode.abs() % Colors.primaries.length;
    return Colors.primaries[idx].shade400;
  }

  // ignore: unused_element
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
        SectionTitle(title: 'Expenses by Category', onSeeAll: widget.onSeeAll),
        const SizedBox(height: 12),
        FutureBuilder<List<_CategoryTotal>>(
          future: _chartDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to get categories data!',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions recorded yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Start by adding your first transaction below.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Add Transaction',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => TransactionFormScreen(
                                      onSaved: (savedTransaction) {
                                        setState(() {
                                          _chartDataFuture = _loadChartData();
                                        });
                                      },
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final totalAll = data.fold<double>(0, (sum, e) => sum + e.amount);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
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
                                radius: 58,
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
                  Column(
                    children:
                        data.map((entry) {
                          final color = _getColor(entry.category.name);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: color.withOpacity(0.05),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: color.withOpacity(0.2),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.category.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                // ✅ Async currency display
                                FutureBuilder<String>(
                                  future: CurrencyFormatter().encode(
                                    entry.amount,
                                  ),
                                  builder: (context, snapshot) {
                                    final amountText = snapshot.data ?? '...';
                                    return Text(
                                      amountText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
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
