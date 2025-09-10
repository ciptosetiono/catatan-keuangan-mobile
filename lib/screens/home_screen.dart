// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:money_note/components/dashboards/wallets_balance_section.dart';
import 'package:money_note/components/dashboards/summary_section.dart';
import 'package:money_note/components/dashboards/spending_chart_section.dart';
import 'package:money_note/components/dashboards/recent_transactions_section.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/screens/wallets/wallet_screen.dart';
import 'package:money_note/screens/categories/category_screen.dart';
import 'package:money_note/screens/transactions/transaction_screen.dart';
import 'package:money_note/screens/transactions/transaction_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _goToWallets(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletScreen()),
    );
  }

  void _goToSpendingChart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryScreen()),
    );
  }

  void _goToTransactions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionScreen()),
    );
  }

  void _goToDetailTransaction(TransactionModel trx, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: trx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WalletsBalanceSection(onSeeAll: () => _goToWallets(context)),
            const SizedBox(height: 24),
            SummarySection(onSeeAll: () => _goToTransactions(context)),
            const SizedBox(height: 24),
            SpendingChartSection(onSeeAll: () => _goToSpendingChart(context)),
            const SizedBox(height: 24),
            RecentTransactionsSection(
              onSeeAll: () => _goToTransactions(context),
              onTapItem: (trx) => _goToDetailTransaction(trx, context),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
