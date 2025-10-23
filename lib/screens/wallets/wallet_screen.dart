// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';

import 'package:money_note/components/wallets/wallet_list_item.dart';
import 'package:money_note/components/wallets/wallet_delete_dialog.dart';
import 'package:money_note/models/wallet_model.dart';

import 'package:money_note/services/sqlite/wallet_service.dart';
import 'package:money_note/components/ads/banner_ad_widget.dart';
import 'package:money_note/screens/wallets/wallet_form_screen.dart';
import 'package:money_note/screens/wallets/wallet_detail_screen.dart';
import 'package:money_note/screens/transfers/transfer_screen.dart';
import '../../utils/currency_formatter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  Future<double> getTotalBalance() async {
    List<Wallet> wallets = await WalletService().getWallets();
    double total = wallets.fold(
      0,
      (sum, wallet) => sum + wallet.currentBalance,
    );
    return total;
  }

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
    await showWalletDeleteDialog(
      context: context,
      walletId: wallet.id,
      onDeleted: () {
        if (!mounted) return;
      },
    );
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
    final Future<double> _totalBalance = getTotalBalance();

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

      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<double>(
                    future: _totalBalance,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 100,
                          height: 20,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final total = snapshot.data ?? 0.0;
                      return Text(
                        CurrencyFormatter().encode(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Wallet>>(
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
                      onTapDown:
                          (details) => _tapPosition = details.globalPosition,
                      onTap: () => _showPopupMenu(wallet, _tapPosition),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: const BannerAdWidget(),
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
