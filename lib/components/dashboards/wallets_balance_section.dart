import 'package:flutter/material.dart';

import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/wallet_model.dart';

import 'package:money_note/services/sqlite/wallet_service.dart';

import 'package:money_note/screens/wallets/wallet_detail_screen.dart';

import 'package:money_note/components/dashboards/section_title.dart';

class WalletsBalanceSection extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const WalletsBalanceSection({super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Wallets', onSeeAll: onSeeAll),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: StreamBuilder<List<Wallet>>(
            stream: WalletService().getWalletStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final wallets = snapshot.data ?? [];

              if (wallets.isEmpty) {
                return const Center(child: Text('There is no wallet.'));
              }

              // ambil maksimal 2 wallet
              final limitedWallets =
                  wallets.length > 2 ? wallets.sublist(0, 2) : wallets;

              return Row(
                children:
                    limitedWallets.map((wallet) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _WalletCard(
                            wallet: wallet,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => WalletDetailScreen(wallet: wallet),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback? onTap;

  const _WalletCard({required this.wallet, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(wallet.name, style: TextStyle(color: Colors.black54)),
              const Spacer(),
              Text(
                CurrencyFormatter().encode(wallet.currentBalance),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
