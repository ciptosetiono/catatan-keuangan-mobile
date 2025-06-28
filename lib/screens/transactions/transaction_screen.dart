// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../components/filters/account_filter_dropdown.dart';
import '../../../components/filters/date_filter_dropdown.dart';
import '../../../components/filters/unified_filter_dialog.dart';
import '../../../components/transactions/transaction_action_dialog.dart';
import '../../../components/transactions/transaction_delete_dialog.dart';
import '../../../components/transactions/transaction_list_item.dart';
import '../../../components/transactions/transaction_summary_card.dart';

import '../../constants/date_filter_option.dart';
import '../../services/transaction_service.dart';
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month + 1);
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
  }

  void _applyUnifiedFilter({String? type, String? category, String? title}) {
    setState(() {
      _typeFilter = type;
      _categoryFilter = category;
      _titleFilter = title;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getTransactions() {
    return TransactionService().getTransactions(
      fromDate: _from,
      toDate: _to,
      type: _typeFilter,
      walletId: _accountFilter,
      categoryId: _categoryFilter,
      title: _titleFilter,
    );
  }

  Future<Map<String, num>> _calculateSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    num income = 0;
    num expense = 0;

    for (var doc in docs) {
      final data = doc.data();
      final amount = data['amount'] ?? 0;
      final type = data['type'];

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
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final selected = await showTransactionActionDialog(context);

    if (selected == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => TransactionFormScreen(
                transactionId: doc.id,
                existingData: doc.data(),
              ),
        ),
      );
    } else if (selected == 'delete') {
      final confirm = await showTransactionDeleteDialog(context);
      if (confirm) {
        await TransactionService().deleteTransaction(doc.id);
      }
    }
  }

  Widget _buildSummaryItem({
    required String label,
    required num value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: 'id', symbol: 'Rp').format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
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
                    onChanged: (val) => setState(() => _accountFilter = val),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('❌ Error dari snapshot: ${snapshot.error}');
            return Text(
              'Terjadi kesalahan, tidak dapat mengambil data transaksi',
            );
          }

          final data = snapshot.data?.docs ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada transaksi'));
          }

          return FutureBuilder<Map<String, num>>(
            future: _calculateSummary(data),
            builder: (context, summarySnapshot) {
              if (!summarySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final summary = summarySnapshot.data!;
              final income = summary['income']!;
              final expense = summary['expense']!;
              final balance = summary['balance']!;

              return Column(
                children: [
                  TransactionSummaryCard(
                    income: income,
                    expense: expense,
                    balance: balance,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: data.length,
                      itemBuilder:
                          (ctx, i) => TransactionListItem(
                            transaction: data[i],
                            onTap:
                                () => _handleTransactionTap(context, data[i]),
                          ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
