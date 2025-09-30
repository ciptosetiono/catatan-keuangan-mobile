// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase/auth_service.dart';
import '../categories/category_screen.dart';
import '../wallets/wallet_screen.dart';
import '../transfers/transfer_screen.dart';
import '../../services/sqlite/backup_service.dart';
import 'package:money_note/components/ui/alerts/flash_message.dart';

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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (user != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                    child:
                        user.photoURL == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

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

          // Logout
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Exit',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              onTap: () async {
                await AuthService().signOut();
                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ),
        ],
      ),
    );
  }
}
