// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../categories/category_screen.dart';
import '../wallets/wallet_screen.dart';
import '../transfers/transfer_screen.dart';
import 'default_settings_screen.dart';
import 'currency_setting_screen.dart';
import '../../components/settings/setting_menu_tile.dart';
import 'backup_menu_screen.dart';
import 'restore_menu_screen.dart';
import '../../components/ads/banner_ad_widget.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  Future<void> _rateApp(BuildContext context) async {
    final inAppReview = InAppReview.instance;

    try {
      // 1. Try launching in-app review
      final available = await inAppReview.isAvailable();
      if (!available) {
        // Not available -> open store directly
        await inAppReview.openStoreListing();
        return;
      }

      // 2. Request review
      await inAppReview.requestReview();

      // 3. Wait 1 second to see if dialog appears.
      // If dialog doesn't show, Google ignores it -> fallback.
      Future.delayed(const Duration(seconds: 1), () async {
        // If the dialog did not appear, we fallback to Play Store.
        // Note: There's no official "didShow" event.
        await inAppReview.openStoreListing();
      });
    } catch (e) {
      // If something actually crashed, fallback too
      await inAppReview.openStoreListing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          SettingMenuTile(
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
            title: 'Wallets',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                ),
          ),

          SettingMenuTile(
            icon: Icons.compare_arrows_rounded,
            color: Colors.orange,
            title: 'Transfers',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferScreen()),
                ),
          ),
          SettingMenuTile(
            icon: Icons.category,
            color: Colors.green,
            title: 'Categories',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()),
                ),
          ),
          SettingMenuTile(
            icon: Icons.settings_suggest_rounded,
            color: Colors.indigo,
            title: 'Default Values',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DefaultSettingsScreen(),
                  ),
                ),
          ),
          SettingMenuTile(
            icon: Icons.currency_exchange_rounded,
            color: Colors.cyan,
            title: 'Currency Setting',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingCurrencyScreen(),
                  ),
                ),
          ),

          // 🗂 Backup (Submenu)
          SettingMenuTile(
            icon: Icons.backup_outlined,
            color: Colors.purple,
            title: 'Backup',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupMenuScreen()),
                ),
          ),

          // ♻ Restore (Submenu)
          SettingMenuTile(
            icon: Icons.restore,
            color: Colors.teal,
            title: 'Restore',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RestoreMenuScreen()),
                ),
          ),
          // ⭐ Rate App
          SettingMenuTile(
            icon: Icons.star_rate_rounded,
            color: Colors.amber,
            title: 'Rate Us',
            onTap: () => _rateApp(context),
          ),

          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
