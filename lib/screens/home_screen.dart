// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../components/dashboards/wallets_balance_section.dart';
import '../components/dashboards/summary_section.dart';
import '../components/dashboards/spending_chart_section.dart';
import '../components/dashboards/recent_transactions_section.dart';
import '../screens/wallets/wallet_screen.dart';
import '../screens/categories/category_screen.dart';
import '../screens/transactions/transaction_screen.dart';

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
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
