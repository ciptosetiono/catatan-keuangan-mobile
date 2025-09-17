import 'package:flutter/material.dart';

import 'package:money_note/constants/date_filter_option.dart';
import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/components/transactions/transaction_list_item.dart';
import 'package:money_note/components/forms/date_filter_dropdown.dart';
import 'package:money_note/components/categories/category_bottomsheet_menu.dart';

import 'package:money_note/models/category_model.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/transaction_service.dart';
import 'package:money_note/services/category_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late Category _category;
  DateTime? _from;
  DateTime? _to;
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;
  String? _selectedDateLabel;
  void _applyDateFilter(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  }) {
    setState(() {
      _selectedDateFilter = option;
      _from = from;
      _to = to;
      _selectedDateLabel = label;
    });
  }

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  Widget _buildTransactionsSection() {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService().getTransactionsStream(
        categoryId: _category.id,
        fromDate: _from,
        toDate: _to,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        final totalAmount = transactions.fold<double>(
          0,
          (sum, tx) => sum + tx.amount,
        );

        return Column(
          children: [
            // Total summary card
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Transactions",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter().encode(totalAmount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "${transactions.length} items",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List transaksi
            Expanded(
              child:
                  transactions.isEmpty
                      ? const Center(child: Text("No transactions found"))
                      : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return TransactionListItem(
                            transaction: transaction,
                            onUpdated: () => setState(() {}),
                            onDeleted: () => setState(() {}),
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _category.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(_category.type, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter row
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Transactions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 0,
                    ),
                    child: DateFilterDropdown(
                      selected: _selectedDateFilter,
                      label: _selectedDateLabel,
                      onFilterApplied: _applyDateFilter,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Transactions section
            Expanded(child: _buildTransactionsSection()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.more_vert),
        onPressed:
            () => showCategoryBottomsheetMenu(
              context: context,
              category: _category,
              onCategoryUpdated: () async {
                final updatedCategory = await CategoryService().getCategoryById(
                  _category.id,
                );
                if (updatedCategory != null) {
                  setState(() {
                    _category = updatedCategory;
                  });
                }
              },
              onCategoryDeleted: () {
                Navigator.pop(context, true);
              },
            ),
      ),
    );
  }
}
