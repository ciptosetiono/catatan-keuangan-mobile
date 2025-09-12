import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/utils/date_formatter.dart';

import 'package:money_note/models/budget_model.dart';

import 'package:money_note/models/category_model.dart';
import 'package:money_note/models/transaction_model.dart';

import 'package:money_note/services/budget_service.dart';
import 'package:money_note/services/category_service.dart';
import 'package:money_note/services/transaction_service.dart';

import 'package:money_note/components/transactions/transaction_list_item.dart';
import 'package:money_note/components/budgets/budget_delete_dialog.dart';

import 'package:money_note/screens/budgets/budget_form_screen.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;
  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  Budget? _localBudget;
  String categoryName = '-';
  List<TransactionModel> transactions = [];
  bool isLoading = true;
  // ignore: unused_field
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _localBudget = widget.budget;
    loadCategoryName();
    loadTransactions();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadCategoryName() async {
    final Category category = await CategoryService().getCategoryById(
      widget.budget.categoryId,
    );
    setState(() {
      categoryName = category.name.isNotEmpty ? category.name : '-';
    });
  }

  Future<void> loadTransactions() async {
    final stream = TransactionService().getTransactionsStream(
      categoryId: widget.budget.categoryId,
      type: 'expense',
      fromDate: DateTime(
        widget.budget.month.year,
        widget.budget.month.month,
        1,
      ),
      toDate: DateTime(
        widget.budget.month.year,
        widget.budget.month.month + 1,
        0,
      ),
    );
    stream.listen((trxList) {
      setState(() {
        transactions = trxList;
      });
    });
  }

  double get totalExpense {
    return transactions.fold(0, (sum, trx) => sum + trx.amount);
  }

  double get remainingBudget {
    return (_localBudget?.amount ?? 0) - totalExpense;
  }

  double get progress {
    if (widget.budget.amount == 0) return 0;
    final value = totalExpense / widget.budget.amount;
    return value.clamp(0.0, 1.0);
  }

  Color get progressColor {
    return remainingBudget < 0 ? Colors.redAccent : Colors.green;
  }

  String formatMonth(DateTime date) {
    return DateFormat.yMMMM().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Detail'),
        backgroundColor: Colors.lightBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BudgetFormScreen(budget: widget.budget),
                  ),
                );

                if (result == true) {
                  final updated = await BudgetService().getBudget(
                    widget.budget.id,
                  );
                  setState(() {
                    _localBudget = updated;
                    _hasChanged = true;
                  });
                  await loadCategoryName();
                  await loadTransactions();
                }
              } else if (value == 'delete') {
                await showBudgetDeleteDialog(
                  context: context,
                  budgetId: widget.budget.id,
                  onDeleted: () async {
                    Navigator.of(context).pop(true);
                  },
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Budget'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete Budget'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.green),
                        const SizedBox(width: 12),
                        Text(
                          CurrencyFormatter().encode(_localBudget?.amount ?? 0),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.category, color: Color(0xFF838B99)),
                        const SizedBox(width: 12),
                        Text(
                          categoryName,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormatter().formatMonth(
                            _localBudget?.month ?? DateTime.now(),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.trending_down, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Total Expense'),
                          ],
                        ),
                        Text(
                          CurrencyFormatter().encode(totalExpense),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.savings, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Remaining'),
                          ],
                        ),
                        Text(
                          CurrencyFormatter().encode(remainingBudget),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                remainingBudget < 0
                                    ? Colors.redAccent
                                    : const Color.fromARGB(255, 64, 98, 253),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% used from budget',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                ? const Text('No Expense.')
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final trx = transactions[index];
                    return TransactionListItem(
                      transaction: trx,
                      onUpdated: () => loadTransactions(),
                      onDeleted: () => loadTransactions(),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
