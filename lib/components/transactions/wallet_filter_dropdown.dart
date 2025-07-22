import 'package:flutter/material.dart';

import '../../../models/wallet_model.dart';
import '../../../services/wallet_service.dart';

class WalletFilterDropdown extends StatelessWidget {
  final String? value;
  final String? placeholder;
  final void Function(String?) onChanged;

  const WalletFilterDropdown({
    super.key,
    required this.value,
    this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<List<Wallet>>(
              stream: WalletService().getWalletStream(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const SizedBox.shrink(), // Hide default icon
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    hint: const Text(
                      'Wallet',
                      style: TextStyle(color: Colors.black),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(placeholder ?? 'Select Wallet'),
                      ),
                      ...items.map(
                        (wallet) => DropdownMenuItem<String>(
                          value: wallet.id,
                          child: Text(wallet.name),
                        ),
                      ),
                    ],
                    onChanged: onChanged,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.account_balance_wallet, color: Colors.black),
        ],
      ),
    );
  }
}
