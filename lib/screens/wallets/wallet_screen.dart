// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';

import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';
import 'wallet_form_screen.dart';
import 'wallet_detail_screen.dart';
import '../../screens/transfers/transfer_screen.dart';
import '../../components/wallets/wallet_list_item.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  void _navigateToDetail({Wallet? wallet}) {
    if (wallet != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WalletDetailScreen(wallet: wallet)),
      );
    }
  }

  void _navigateToForm({Wallet? wallet}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WalletFormScreen(wallet: wallet)),
    );
  }

  void _navigateToTransferScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransferScreen()),
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
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _walletService.deleteWallet(wallet.id);
      if (!mounted) return;
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
        const PopupMenuItem(value: 'detail', child: Text('Detail')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );

    if (selected == 'detail') {
      _navigateToDetail(wallet: wallet);
    } else if (selected == 'edit') {
      _navigateToForm(wallet: wallet);
    } else if (selected == 'delete') {
      _deleteWallet(wallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    Offset _tapPosition = Offset.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: _navigateToTransferScreen,
              child: Row(
                children: const [
                  Icon(Icons.compare_arrows_rounded),
                  SizedBox(width: 4),
                  Text(
                    'Transfers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

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
              return WalletListItem(
                wallet: wallet,
                onTapDown: (details) => _tapPosition = details.globalPosition,
                onTap: () => _showPopupMenu(wallet, _tapPosition),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addWallet',
        onPressed: () => _navigateToForm(),
        // ignore: sort_child_properties_last
        child: const Icon(Icons.add),
        tooltip: 'Add Wallet',
        backgroundColor: Colors.green,
      ),
    );
  }
}
