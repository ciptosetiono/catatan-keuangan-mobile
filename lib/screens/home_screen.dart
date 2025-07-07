// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../components/dashboards/wallets_balance_section.dart';
import '../components/dashboards/summary_section.dart';
import '../components/dashboards/spending_chart_section.dart';
import '../components/dashboards/recent_transactions_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _goToWallets(BuildContext context) {
    Navigator.pushNamed(context, '/wallets');
  }

  void _goToSpendingChart(BuildContext context) {
    Navigator.pushNamed(context, '/categoryReport');
  }

  void _goToSummaryReport(BuildContext context) {
    Navigator.pushNamed(context, '/summaryReport');
  }

  void _goToTransactions(BuildContext context) {
    Navigator.pushNamed(context, '/transactions');
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
            SummarySection(onSeeAll: () => _goToSummaryReport(context)),
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
