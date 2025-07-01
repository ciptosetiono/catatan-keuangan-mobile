import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../models/category_model.dart';

import '../../services/wallet_service.dart';
import '../../services/category_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  String walletName = '-';
  String categoryName = '-';

  @override
  void initState() {
    super.initState();
    loadNames();
  }

  Future<void> loadNames() async {
    final wallet = await getWalletName(widget.transaction.walletId);
    final category = await getCategoryName(widget.transaction.categoryId);

    setState(() {
      walletName = wallet;
      categoryName = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(decimalDigits: 0, symbol: '');
    final formatDate = DateFormat('EEEE, d MMMM yyyy');

    final isIncome = widget.transaction.type == 'income';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaction'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan icon dan jumlah
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isIncome ? Colors.green : Colors.red,
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatCurrency.format(widget.transaction.amount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        isIncome ? 'Income' : 'Expense',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailTile(
              Icons.calendar_today,
              'Date',
              formatDate.format(widget.transaction.date),
            ),
            _buildDetailTile(
              Icons.account_balance_wallet,
              'Wallet',
              walletName,
            ),
            _buildDetailTile(Icons.category, 'Category', categoryName),
            _buildDetailTile(Icons.note, 'Note', widget.transaction.title),
          ],
        ),
      ),
    );
  }

  Future<String> getWalletName(String? walletId) async {
    if (walletId == null) return '-';
    final Wallet wallet = await WalletService().getWalletById(walletId);
    if (wallet.id.isEmpty) return '-';
    return wallet.name.isNotEmpty ? wallet.name : '-';
  }

  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null) return '-';
    final Category category = await CategoryService().getCategoryById(
      categoryId,
    );
    if (category.id.isEmpty) return '-';
    return category.name.isNotEmpty ? category.name : '-';
  }
}

Widget _buildDetailTile(IconData icon, String label, String value) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
