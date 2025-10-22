import 'package:flutter/material.dart';

import 'package:money_note/models/wallet_model.dart';

import 'package:money_note/services/sqlite/wallet_service.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<List<Wallet>>(
              stream: WalletService().getWalletStream(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black54,
                    ),
                    dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    hint: Text(
                      placeholder ?? 'All Wallets',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          placeholder ?? 'All Wallets',
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...items.map(
                        (wallet) => DropdownMenuItem<String>(
                          value: wallet.id,
                          child: Text(
                            wallet.name,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onChanged,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
