import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/components/transactions/transaction_summary_card.dart';
import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/transaction_service.dart';

import 'package:money_note/components/alerts/not_found_data_message.dart';
import 'package:money_note/components/transactions/transaction_list.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  final currency = CurrencyFormatter();
  final dateFormat = DateFormat('dd MMM yyyy');

  List<TransactionModel> _transactions = [];
  Map<String, num> _summary = {'income': 0, 'expense': 0, 'balance': 0};

  String _selectedFilter = 'All';
  DateTimeRange? _customDateRange;

  Stream<List<TransactionModel>> _getFilteredTransactions() {
    return _transactionService.getTransactionsByWallet(widget.wallet.id).map((
      list,
    ) {
      List<TransactionModel> filtered = list;

      DateTime now = DateTime.now();

      if (_selectedFilter == 'Today') {
        filtered =
            filtered
                .where(
                  (tx) =>
                      tx.date.year == now.year &&
                      tx.date.month == now.month &&
                      tx.date.day == now.day,
                )
                .toList();
      } else if (_selectedFilter == 'This Month') {
        filtered =
            filtered
                .where(
                  (tx) =>
                      tx.date.year == now.year && tx.date.month == now.month,
                )
                .toList();
      } else if (_selectedFilter == 'Custom' && _customDateRange != null) {
        filtered =
            filtered
                .where(
                  (tx) =>
                      tx.date.isAfter(
                        _customDateRange!.start.subtract(
                          const Duration(days: 1),
                        ),
                      ) &&
                      tx.date.isBefore(
                        _customDateRange!.end.add(const Duration(days: 1)),
                      ),
                )
                .toList();
      }

      // Hitung summary
      _calculateSummary(filtered);

      return filtered;
    });
  }

  void _calculateSummary(List<TransactionModel> transactions) {
    final income = transactions
        .where((t) => t.type == 'income')
        .fold<num>(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == 'expense')
        .fold<num>(0, (sum, t) => sum + t.amount);

    setState(() {
      _summary = {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    });
  }

  void _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedFilter = 'Custom';
        _customDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Detail')),
      body: Column(
        children: [
          // Wallet info card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${dateFormat.format(wallet.createdAt)}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _balanceInfo(
                          "Start Balance",
                          currency.encode(wallet.startBalance),
                        ),
                        _balanceInfo(
                          "Current Balance",
                          currency.encode(wallet.currentBalance),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Summary Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TransactionSummaryCard(
              income: _summary['income']!,
              expense: _summary['expense']!,
              balance: _summary['balance']!,
            ),
          ),

          // Transactions header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transactions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items:
                      ['All', 'Today', 'This Month', 'Custom']
                          .map(
                            (label) => DropdownMenuItem(
                              value: label,
                              child: Text(label),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value == 'Custom') {
                      _pickCustomDateRange();
                    } else {
                      setState(() => _selectedFilter = value!);
                    }
                  },
                ),
              ],
            ),
          ),

          // Transaction list
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _getFilteredTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return const NotFoundDataMessage(
                    message: "No transactions found.",
                  );
                }

                return TransactionList(transactions: transactions);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
