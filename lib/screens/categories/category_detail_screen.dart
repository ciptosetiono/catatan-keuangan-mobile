import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/constants/date_filter_option.dart';

import 'package:money_note/models/category_model.dart';
import 'package:money_note/models/transaction_model.dart';

import 'package:money_note/services/category_service.dart';
import 'package:money_note/services/transaction_service.dart';

import 'package:money_note/components/transactions/date_filter_dropdown.dart';
import 'package:money_note/components/transactions/transaction_list_item.dart';
import 'package:money_note/components/transactions/transaction_summary_card.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  Category? _category;
  final currency = CurrencyFormatter();
  final dateFormat = DateFormat('dd MMM yyyy');

  DateTime? _from;
  DateTime? _to;
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;

  Map<String, num> _summary = {'income': 0, 'expense': 0, 'balance': 0};

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  /// Apply filter date
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
    });
  }

  Future<void> _loadCategory() async {
    final updatedCategory = await CategoryService().getCategoryById(
      widget.category.id,
    );

    if (updatedCategory != null) {
      setState(() {
        _category = updatedCategory;
      });
    }
  }

  /// Get transaction stream for this category
  Stream<List<TransactionModel>> _transactionStream() {
    return TransactionService().getTransactionsStream(
      categoryId: widget.category.id,
      fromDate: _from,
      toDate: _to,
    );
  }

  /// Recalculate income/expense/balance summary
  void _calculateSummary(List<TransactionModel> transactions) {
    num income = 0;
    num expense = 0;

    for (var tx in transactions) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    setState(() {
      _summary = {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = _category ?? widget.category;

    return Scaffold(
      appBar: AppBar(title: const Text('Category Detail')),
      body: Column(
        children: [
          // Category info card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.category, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.type,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Transactions header & filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transactions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DateFilterDropdown(
                  selected: _selectedDateFilter,
                  onFilterApplied: _applyDateFilter,
                ),
              ],
            ),
          ),

          // Transaction list & summary
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data ?? [];

                _calculateSummary(transactions);

                if (transactions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "No transactions found.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Summary Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TransactionSummaryCard(
                        income: _summary['income']!,
                        expense: _summary['expense']!,
                        balance: _summary['balance']!,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Transaction list
                    Expanded(
                      child: ListView.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return TransactionListItem(
                            transaction: transaction,
                            onUpdated: () => _loadCategory(),
                            onDeleted: () => _loadCategory(),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
