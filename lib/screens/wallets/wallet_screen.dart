import 'package:flutter/material.dart';

import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';
import '../../utils/currency_formatter.dart';
import 'wallet_form_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  void _navigateToForm({Wallet? wallet}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WalletFormScreen(wallet: wallet)),
    );
  }

  void _deleteWallet(Wallet wallet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Wallet'),
            content: Text('Are you sure you want to delete "${wallet.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _walletService.deleteWallet(wallet.id);
    }
  }

  void _showPopupMenu(Wallet wallet, Offset tapPosition) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        tapPosition.dx,
        tapPosition.dy,
      ),
      items: [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );

    if (selected == 'edit') {
      _navigateToForm(wallet: wallet);
    } else if (selected == 'delete') {
      _deleteWallet(wallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    Offset _tapPosition = Offset.zero;

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallets')),
      body: StreamBuilder<List<Wallet>>(
        stream: _walletService.getWalletStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final wallets = snapshot.data ?? [];
          if (wallets.isEmpty) {
            return const Center(child: Text('There are no wallets yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: wallets.length,
            itemBuilder: (ctx, i) {
              final wallet = wallets[i];
              return GestureDetector(
                onTapDown: (details) => _tapPosition = details.globalPosition,
                onTap: () => _showPopupMenu(wallet, _tapPosition),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.blue,
                    ),
                    title: Text(
                      wallet.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'start Balance: ${CurrencyFormatter().encode(wallet.startBalance)}',
                        ),
                        Text(
                          'Current Balance: ${CurrencyFormatter().encode(wallet.currentBalance)}',
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
