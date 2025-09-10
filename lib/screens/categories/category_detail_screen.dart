import 'package:flutter/material.dart';

import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/category_model.dart';
import 'package:money_note/models/transaction_model.dart';

import 'package:money_note/services/category_service.dart';
import 'package:money_note/services/transaction_service.dart';

import 'package:money_note/components/transactions/transaction_list_item.dart';
import 'package:money_note/components/transactions/transaction_action_dialog.dart';
import 'package:money_note/components/transactions/date_filter_dropdown.dart';
import 'package:money_note/components/categories/category_delete_dialog.dart';
import 'package:money_note/constants/date_filter_option.dart';

import 'package:money_note/screens/transactions/transaction_detail_screen.dart';
import 'package:money_note/screens/transactions/transaction_form_screen.dart';
import 'package:money_note/screens/categories/category_form_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  Category? _category;

  DateTime? _from;
  DateTime? _to;
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;

  List<TransactionModel> transactions = [];
  bool isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    loadTransactions();
  }

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
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final stream = TransactionService().getTransactionsStream(
      categoryId: widget.category.id,
      fromDate: _from,
      toDate: _to,
    );
    stream.listen((trxList) {
      setState(() {
        transactions = trxList;
        isLoading = false;
      });
    });
  }

  double get totalTransaction {
    return transactions.fold(0, (sum, trx) => sum + trx.amount);
  }

  Future<void> _handleTransactionTap(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final selected = await showTransactionActionDialog(context);

    if (selected == 'detail') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: transaction),
        ),
      );
    } else if (selected == 'edit') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => TransactionFormScreen(
                transactionId: transaction.id,
                existingData: transaction,
              ),
        ),
      );

      if (result == true) {
        final updatedCategory = await CategoryService().getCategoryById(
          widget.category.id,
        );
        setState(() {
          _category = updatedCategory;
          _hasChanged = true;
        });
        loadTransactions();
      }
    } else if (selected == 'delete') {
      await confirmAndDeleteCategory(
        context: context,
        categoryId: widget.category.id,
        onDeleted: () {
          loadTransactions();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.category.type == 'income';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.category.type,
              style: TextStyle(
                fontSize: 14,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanged),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryFormScreen(category: _category),
                  ),
                );

                if (result == true) {
                  final updatedCategory = await CategoryService()
                      .getCategoryById(widget.category.id);
                  setState(() {
                    _category = updatedCategory;
                    _hasChanged = true;
                  });
                  await loadTransactions();
                }
              } else if (value == 'delete') {
                await confirmAndDeleteCategory(
                  context: context,
                  categoryId: widget.category.id,
                  onDeleted: () {
                    loadTransactions();
                  },
                );
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Category'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete Category'),
                    ),
                  ),
                ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DateFilterDropdown(
                selected: _selectedDateFilter,
                onFilterApplied: _applyDateFilter,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Total Transactions Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: const Text(
                  "Total Transactions",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  CurrencyFormatter().encode(totalTransaction),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // Transactions list
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty
                    ? const Center(child: Text('No Transactions found.'))
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final trx = transactions[index];
                        return TransactionListItem(
                          transaction: trx,
                          onTap: () => _handleTransactionTap(context, trx),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
