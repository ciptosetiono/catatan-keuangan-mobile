// ignore_for_file: use_build_context_synchronously, prefer_final_fields

import 'package:flutter/material.dart';

import 'package:money_note/constants/date_filter_option.dart';
import 'package:money_note/components/buttons/add_button.dart';
import 'package:money_note/components/buttons/filter_button.dart';
import 'package:money_note/components/wallets/wallet_filter_dropdown.dart';
import 'package:money_note/components/forms/date_filter_dropdown.dart';
import 'package:money_note/components/transactions/unified_filter_dialog.dart';
import 'package:money_note/components/transactions/transaction_list.dart';
import 'package:money_note/components/transactions/transaction_summary_card.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/sqlite/transaction_service.dart';
import 'package:money_note/screens/transactions/transaction_form_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime? _from;
  DateTime? _to;
  DateFilterOption _selectedDateFilter = DateFilterOption.thisMonth;
  String? _selectedDateLabel;
  final ScrollController _scrollController = ScrollController();

  String? _walletFilter;
  String? _typeFilter;
  String? _categoryFilter;
  String? _titleFilter;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month + 1);

    _loadTransactions(reset: true);

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
      _offset = 0;
      _hasMore = true;
      setState(() {});
    }

    try {
      const limit = 20;

      final newTransactions = await TransactionService()
          .getTransactionsPaginated(
            limit: limit,
            offset: _offset,
            fromDate: _from,
            toDate: _to,
            type: _typeFilter,
            walletId: _walletFilter,
            categoryId: _categoryFilter,
            title: _titleFilter,
          );

      if (!mounted) return;

      setState(() {
        _transactions.addAll(newTransactions);
        _offset += newTransactions.length;
        if (newTransactions.length < limit) _hasMore = false;
      });
    } catch (e) {
      debugPrint("Error loading transactions: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyDateFilter(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  }) {
    if (!mounted) return;
    setState(() {
      _selectedDateFilter = option;
      _selectedDateLabel = label;
      _from = from;
      _to = to;
    });
    _loadTransactions(reset: true);
  }

  void _applyUnifiedFilter({
    String? type,
    String? wallet,
    String? category,
    String? title,
  }) {
    if (!mounted) return;
    setState(() {
      _typeFilter = type;
      _walletFilter = wallet;
      _categoryFilter = category;
      _titleFilter = title;
    });
    _loadTransactions(reset: true);
  }

  Widget _buildSummary() {
    return FutureBuilder<Map<String, num>>(
      future: TransactionService().getSummary(
        fromDate: _from,
        toDate: _to,
        type: _typeFilter,
        walletId: _walletFilter,
        categoryId: _categoryFilter,
        title: _titleFilter,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final summary = snapshot.data!;
        final income = summary['income'] ?? 0;
        final expense = summary['expense'] ?? 0;

        return TransactionSummaryCard(
          income: income,
          expense: expense,
          balance: income - expense,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: DateFilterDropdown(
                    selected: _selectedDateFilter,
                    onFilterApplied: _applyDateFilter,
                    label: _selectedDateLabel,
                  ),
                ),
                Expanded(
                  child: WalletFilterDropdown(
                    value: _walletFilter,
                    onChanged: (val) {
                      if (!mounted) return;
                      setState(() => _walletFilter = val);
                      _loadTransactions(reset: true);
                    },
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: FilterButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => UnifiedFilterDialog(
                              typeFilter: _typeFilter,
                              walletFilter: _walletFilter,
                              categoryFilter: _categoryFilter,
                              titleFilter: _titleFilter,
                              onFilterApplied: _applyUnifiedFilter,
                            ),
                      );
                    },
                  ),
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
                      onItemUpdated: (updatedTransaction) {
                        _loadTransactions(reset: true);
                      },
                      onItemDeleted: () {
                        _loadTransactions(reset: true);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: AddButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => TransactionFormScreen(
                    onSaved: (updatedTransaction) {
                      _loadTransactions(reset: true);
                    },
                  ),
            ),
          );
        },
      ),
    );
  }
}
