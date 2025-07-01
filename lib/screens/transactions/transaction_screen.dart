// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../components/transactions/account_filter_dropdown.dart';
import '../../components/transactions/date_filter_dropdown.dart';
import '../../components/transactions/unified_filter_dialog.dart';
import '../../../components/transactions/transaction_action_dialog.dart';
import '../../../components/transactions/transaction_delete_dialog.dart';
import '../../../components/transactions/transaction_list_item.dart';
import '../../../components/transactions/transaction_summary_card.dart';

import '../../constants/date_filter_option.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import 'transaction_detail_screen.dart';
import 'transaction_form_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime? _from;
  DateTime? _to;
  String _dateFilterLabel = 'Bulan Ini';
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;

  String? _accountFilter;
  String? _typeFilter;
  String? _categoryFilter;
  String? _titleFilter;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month + 1);
    _loadTransactions();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading &&
          _hasMore) {
        _loadTransactions();
      }
    });
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (reset) {
      _transactions.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    final snapshot = await TransactionService().getTransactionsPaginated(
      limit: 20,
      startAfter: _lastDocument,
      fromDate: _from,
      toDate: _to,
      type: _typeFilter,
      walletId: _accountFilter,
      categoryId: _categoryFilter,
      title: _titleFilter,
    );

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      _transactions =
          snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
    }

    if (snapshot.docs.length < 20) {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
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
      _dateFilterLabel = label ?? 'Bulan Ini';
    });
    _loadTransactions(reset: true);
  }

  void _applyUnifiedFilter({String? type, String? category, String? title}) {
    setState(() {
      _typeFilter = type;
      _categoryFilter = category;
      _titleFilter = title;
    });
    _loadTransactions(reset: true);
  }

  Future<Map<String, num>> _calculateSummary() async {
    num income = 0;
    num expense = 0;

    for (var _transaction in _transactions) {
      if (_transaction == null) continue;
      final amount = _transaction.amount ?? 0;
      final type = _transaction.type;

      if (type == 'income') {
        income += amount;
      } else if (type == 'expense') {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  Future<void> _handleTransactionTap(
    BuildContext context,
    TransactionModel _transaction,
  ) async {
    final selected = await showTransactionActionDialog(context);

    if (selected == 'detail') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => TransactionDetailScreen(transactionId: _transaction.id),
        ),
      );
    } else if (selected == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => TransactionFormScreen(
                transactionId: _transaction.id,
                existingData: _transaction,
              ),
        ),
      );
    } else if (selected == 'delete') {
      final confirm = await showTransactionDeleteDialog(context);
      if (confirm) {
        await TransactionService().deleteTransaction(_transaction.id);
        _loadTransactions(reset: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: AccountFilterDropdown(
                    value: _accountFilter,
                    onChanged: (val) {
                      setState(() => _accountFilter = val);
                      _loadTransactions(reset: true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DateFilterDropdown(
                    selected: _selectedDateFilter,
                    onFilterApplied: _applyDateFilter,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => UnifiedFilterDialog(
                            typeFilter: _typeFilter,
                            categoryFilter: _categoryFilter,
                            titleFilter: _titleFilter,
                            onFilterApplied: _applyUnifiedFilter,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, num>>(
            future: _calculateSummary(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final summary = snapshot.data!;
              return TransactionSummaryCard(
                income: summary['income']!,
                expense: summary['expense']!,
                balance: summary['balance']!,
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _transactions.length + (_hasMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i < _transactions.length) {
                  final transaction = _transactions[i];
                  return TransactionListItem(
                    transaction: transaction,
                    onTap: () => _handleTransactionTap(context, transaction),
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
          ).then((_) => _loadTransactions(reset: true));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
