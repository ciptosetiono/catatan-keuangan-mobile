// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/services/sqlite/wallet_service.dart';
import 'package:money_note/screens/wallets/wallet_form_screen.dart';
import 'package:money_note/utils/currency_formatter.dart';

class WalletDropdown extends StatefulWidget {
  final String? value;
  final String label;
  final bool? showAddButton;
  final Function(String?) onChanged;

  const WalletDropdown({
    super.key,
    required this.value,
    this.label = 'Select Wallet',
    this.showAddButton = true,
    required this.onChanged,
  });

  @override
  State<WalletDropdown> createState() => _WalletDropdownState();
}

class _WalletDropdownState extends State<WalletDropdown> {
  String? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant WalletDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _currentValue) {
      setState(() => _currentValue = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Wallet>>(
      stream: WalletService().getWalletStream(),
      builder: (context, snapshot) {
        final wallets = snapshot.data ?? [];

        if (_currentValue != null &&
            !wallets.any((w) => w.id == _currentValue)) {
          _currentValue = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Expanded dropdown
                Expanded(
                  child: Container(
                    //height: 48, // keep same height
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentValue,
                        isExpanded: true,
                        hint: Text(
                          'Select Wallet',
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black54,
                        ),
                        items:
                            wallets.map((wallet) {
                              // ignore: unused_local_variable
                              final balanceText = CurrencyFormatter().encode(
                                wallet.currentBalance,
                              );
                              return DropdownMenuItem<String>(
                                value: wallet.id,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          wallet.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Balance (FutureBuilder)
                                    FutureBuilder<String>(
                                      future: CurrencyFormatter().encode(
                                        wallet.currentBalance,
                                      ),
                                      builder: (context, snapshot) {
                                        final balanceText =
                                            snapshot.data ?? '...';
                                        return Text(
                                          balanceText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                wallet.currentBalance >= 0
                                                    ? Colors.green[600]
                                                    : Colors.red[600],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (val) {
                          setState(() => _currentValue = val);
                          widget.onChanged(val);
                        },
                      ),
                    ),
                  ),
                ),

                if (widget.showAddButton == true) ...[
                  const SizedBox(width: 8),
                  // Add wallet button
                  Container(
                    //height: 48,
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        final newWallet = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const WalletFormScreen(showAds: false),
                          ),
                        );
                        if (newWallet is Wallet) {
                          setState(() => _currentValue = newWallet.id);
                          widget.onChanged(newWallet.id);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
