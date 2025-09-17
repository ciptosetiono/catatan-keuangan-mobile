// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';
import '../../utils/currency_formatter.dart'; // untuk format currency

class WalletDropdown extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const WalletDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Wallet>>(
      stream: WalletService().getWalletStream(),
      builder: (context, snapshot) {
        final wallets = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: 'Select Wallet',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          items:
              wallets.map((wallet) {
                final balanceText = CurrencyFormatter().encode(
                  wallet.currentBalance,
                );
                return DropdownMenuItem<String>(
                  value: wallet.id,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            wallet.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        balanceText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              wallet.currentBalance >= 0
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          icon: const Icon(Icons.keyboard_arrow_down),
          iconSize: 24,
          isExpanded: true,
        );
      },
    );
  }
}
