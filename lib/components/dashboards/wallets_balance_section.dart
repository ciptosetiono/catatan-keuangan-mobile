import 'package:flutter/material.dart';

import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/wallet_model.dart';

import 'package:money_note/services/wallet_service.dart';

import 'section_title.dart';

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

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  return _WalletCard(wallet: wallet);
                },
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

  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              wallet.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              CurrencyFormatter().encode(wallet.currentBalance),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
