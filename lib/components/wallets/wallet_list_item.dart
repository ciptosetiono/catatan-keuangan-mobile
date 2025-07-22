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
    return GestureDetector(
      onTapDown: onTapDown,
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                'Start Balance: ${CurrencyFormatter().encode(wallet.startBalance)}',
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
  }
}
