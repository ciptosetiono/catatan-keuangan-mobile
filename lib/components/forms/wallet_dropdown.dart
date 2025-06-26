import 'package:flutter/material.dart';

import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';

class WalletDropdown extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const WalletDropdown({Key? key, required this.value, required this.onChanged})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Wallet>>(
      stream: WalletService().getWalletStream(),
      builder: (context, snapshot) {
        final wallets = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            labelText: 'Akun',
            border: OutlineInputBorder(),
          ),
          items:
              wallets
                  .map(
                    (wallet) => DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Text(wallet.name),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
