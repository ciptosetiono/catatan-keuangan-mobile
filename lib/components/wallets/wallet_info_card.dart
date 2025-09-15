import 'package:flutter/material.dart';

import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/wallet_model.dart';

class WalletInfoCard extends StatefulWidget {
  final Wallet wallet;
  const WalletInfoCard({super.key, required this.wallet});

  @override
  State<WalletInfoCard> createState() => _WalletInfoCardState();
}

class _WalletInfoCardState extends State<WalletInfoCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.wallet.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Saldo: ${CurrencyFormatter().encode(widget.wallet.currentBalance)}",
              style: TextStyle(
                fontSize: 16,
                color:
                    widget.wallet.currentBalance >= 0
                        ? Colors.green
                        : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
