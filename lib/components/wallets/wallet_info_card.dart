// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/wallet_model.dart';

class WalletInfoCard extends StatelessWidget {
  final Wallet wallet;
  const WalletInfoCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    final isPositive = wallet.currentBalance >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isPositive
                  ? [Colors.green.shade400, Colors.green.shade700]
                  : [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Info wallet
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: CurrencyFormatter().encode(wallet.currentBalance),
                  builder: (context, snapshot) {
                    final balanceText = snapshot.data ?? '...';
                    return Text(
                      balanceText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),

            // Icon wallet
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                isPositive ? Icons.account_balance_wallet : Icons.warning_amber,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
