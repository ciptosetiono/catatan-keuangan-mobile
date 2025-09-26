import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';
import '../../utils/currency_formatter.dart';

class WalletListItem extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onTap;
  final GestureTapDownCallback onTapDown;

  const WalletListItem({
    super.key,
    required this.wallet,
    required this.onTap,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = wallet.currentBalance >= 0;

    return GestureDetector(
      onTapDown: onTapDown,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon wallet
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Wallet info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start: ${CurrencyFormatter().encode(wallet.startBalance)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    'Current: ${CurrencyFormatter().encode(wallet.currentBalance)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
