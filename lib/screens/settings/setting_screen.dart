// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../categories/category_screen.dart';
import '../wallets/wallet_screen.dart';
import '../transfers/transfer_screen.dart';
import 'default_settings_screen.dart';
import '../../services/sqlite/backup_service.dart';
import '../../components/ui/alerts/flash_message.dart';
import '../../components/ads/banner_ad_widget.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Wallets
          _buildMenuTile(
            context: context,
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
            title: 'Wallets',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),

          // Transfers
          _buildMenuTile(
            context: context,
            icon: Icons.compare_arrows_rounded,
            color: Colors.orange,
            title: 'Transfers',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransferScreen()),
              );
            },
          ),

          // Categories
          _buildMenuTile(
            context: context,
            icon: Icons.category,
            color: Colors.green,
            title: 'Categories',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryScreen()),
              );
            },
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.settings_suggest_rounded,
            color: Colors.indigo,
            title: 'Default Values',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const DefaultSettingsScreen(), // 👈 your new screen
                ),
              );
            },
          ),

          // Backup
          _buildMenuTile(
            context: context,
            icon: Icons.backup,
            color: Colors.purple,
            title: 'Backup Database',
            onTap: () async {
              try {
                final file = await BackupService.backupDatabase();

                final success = file != null;
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  FlashMessage(
                    color: success ? Colors.green : Colors.red,
                    message:
                        success
                            ? 'Backup success!\nSaved to Directory: Downloads ' // tampilkan path file
                            : 'Backup failed. Please try again.',
                  ),
                );

                // ignore: avoid_print
                if (!success) print('Backup returned null');
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  FlashMessage(
                    color: Colors.red,
                    message:
                        'Something went wrong during backup. Please contact support.',
                  ),
                );
              }
            },
          ),

          // Restore
          _buildMenuTile(
            context: context,
            icon: Icons.restore,
            color: Colors.teal,
            title: 'Restore Database',
            onTap: () async {
              try {
                final success = await BackupService.restoreDatabaseWithPicker();

                if (success) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    FlashMessage(
                      color: Colors.green,
                      message: 'Restore success! Restart app to apply.',
                    ),
                  );
                } else {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    FlashMessage(
                      color: Colors.red,
                      message:
                          'Restore failed. Please select a valid backup file.',
                    ),
                  );
                }
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  FlashMessage(
                    color: Colors.red,
                    message: 'Something went wrong. Please contact support.',
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
