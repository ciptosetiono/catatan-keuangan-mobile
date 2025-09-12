// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:money_note/constants/date_filter_option.dart';
import 'package:money_note/components/buttons/add_button.dart';
import 'package:money_note/components/transactions/wallet_filter_dropdown.dart';
import 'package:money_note/components/transactions/date_filter_dropdown.dart';
import 'package:money_note/components/transactions/unified_filter_dialog.dart';
import 'package:money_note/components/transactions/transaction_action_dialog.dart';
import 'package:money_note/components/transactions/transaction_delete_dialog.dart';
import 'package:money_note/components/transactions/transaction_list.dart';
import 'package:money_note/components/transactions/transaction_summary_card.dart';

import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/transaction_service.dart';
import 'package:money_note/screens/transactions/transaction_detail_screen.dart';
import 'package:money_note/screens/transactions/transaction_form_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime? _from;
  DateTime? _to;
  String _dateFilterLabel = 'This Month';
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;
  final ScrollController _scrollController = ScrollController();

  String? _walletFilter;
  String? _typeFilter;
  String? _categoryFilter;
  String? _titleFilter;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  num _income = 0;
  num _expense = 0;
  bool _isSummaryLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month + 1);

    _loadTransactions(reset: true);
    _loadSummary();

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

    try {
      const limit = 20;
      final snapshot = await TransactionService().getTransactionsPaginated(
        limit: limit,
        startAfter: _lastDocument,
        fromDate: _from,
        toDate: _to,
        type: _typeFilter,
        walletId: _walletFilter,
        categoryId: _categoryFilter,
        title: _titleFilter,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        final newTransactions =
            snapshot.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .toList();

        setState(() {
          _transactions.addAll(newTransactions);
          if (snapshot.docs.length < limit) _hasMore = false;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint("Error loading transactions: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isSummaryLoading = true);
    try {
      final result = await TransactionService().getSummary(
        fromDate: _from,
        toDate: _to,
        type: _typeFilter,
        walletId: _walletFilter,
        categoryId: _categoryFilter,
        title: _titleFilter,
      );

      print(result);
      setState(() {
        _income = result['income'] ?? 0;
        _expense = result['expense'] ?? 0;
      });
    } catch (e) {
      debugPrint("Error load summary: $e");
    } finally {
      setState(() => _isSummaryLoading = false);
    }
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
      _dateFilterLabel = label ?? 'This Month';
    });
    _loadTransactions(reset: true);
    _loadSummary();
  }

  void _applyUnifiedFilter({String? type, String? category, String? title}) {
    setState(() {
      _typeFilter = type;
      _categoryFilter = category;
      _titleFilter = title;
    });
    _loadTransactions(reset: true);
    _loadSummary();
  }

  Widget _buildSummary() {
    if (_isSummaryLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return TransactionSummaryCard(
      income: _income,
      expense: _expense,
      balance: _income - _expense,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: WalletFilterDropdown(
                    value: _walletFilter,
                    onChanged: (val) {
                      setState(() => _walletFilter = val);
                      _loadTransactions(reset: true);
                      _loadSummary();
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
                  icon: const Icon(Icons.filter_list, color: Colors.white),
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
          _buildSummary(),
          Expanded(
            child:
                _transactions.isEmpty && !_isLoading
                    ? const Center(child: Text("No transactions found"))
                    : TransactionList(
                      transactions: _transactions,
                      onItemUpdated: () {
                        _loadTransactions(reset: true);
                        _loadSummary();
                      },
                      onItemDeleted: () {
                        _loadTransactions(reset: true);
                        _loadSummary();
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: AddButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
          ).then((_) {
            _loadTransactions(reset: true);
            _loadSummary();
          });
        },
      ),
    );
  }
}
