import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../utils/currency_formatter.dart';
import '../transactions/transaction_detail_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  final currency = CurrencyFormatter();
  final dateFormat = DateFormat('dd MMM yyyy');
  final TransactionService _transactionService = TransactionService();

  String _selectedFilter = 'All';
  DateTimeRange? _customDateRange;

  Stream<List<TransactionModel>> _getFilteredTransactions() {
    return _transactionService.getTransactionsByWallet(widget.wallet.id).map((
      list,
    ) {
      if (_selectedFilter == 'All') return list;

      DateTime now = DateTime.now();

      if (_selectedFilter == 'Today') {
        return list.where((tx) {
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
        }).toList();
      }

      if (_selectedFilter == 'This Month') {
        return list.where((tx) {
          return tx.date.year == now.year && tx.date.month == now.month;
        }).toList();
      }

      if (_selectedFilter == 'Custom' && _customDateRange != null) {
        return list.where((tx) {
          return tx.date.isAfter(
                _customDateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              tx.date.isBefore(
                _customDateRange!.end.add(const Duration(days: 1)),
              );
        }).toList();
      }

      return list;
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isIncome = tx.type == 'income';
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TransactionDetailScreen(transaction: tx),
                          ),
                        );
                      },
                      leading: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                      title: Text(tx.title),
                      subtitle: Text(dateFormat.format(tx.date)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (isIncome ? '+' : '-') + currency.encode(tx.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isIncome
                                      ? Colors.green[100]
                                      : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isIncome ? 'Income' : 'Expense',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isIncome
                                        ? Colors.green[700]
                                        : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
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
