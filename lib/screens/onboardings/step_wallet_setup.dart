// lib/screens/onboarding/step_wallet_setup.dart
import 'package:flutter/material.dart';
import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/services/sqlite/wallet_service.dart';

class StepWalletSetup extends StatefulWidget {
  const StepWalletSetup({super.key});

  @override
  State<StepWalletSetup> createState() => _StepWalletSetupState();
}

class _StepWalletSetupState extends State<StepWalletSetup> {
  final TextEditingController _nameController = TextEditingController();
  final WalletService _walletService = WalletService();
  List<Wallet> _wallets = [];

  Future<void> _loadWallets() async {
    final data = await _walletService.getWallets();
    setState(() => _wallets = data);
  }

  Future<void> _addWallet() async {
    if (_nameController.text.isEmpty) return;
    await _walletService.addWallet(
      Wallet(
        id: '',
        name: _nameController.text,
        startBalance: 0,
        currentBalance: 0,
        createdAt: DateTime.now(),
      ),
    );
    _nameController.clear();
    _loadWallets();
  }

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Create Your Wallets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g. Cash, Bank BCA',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addWallet,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _wallets.length,
              itemBuilder: (_, i) {
                final w = _wallets[i];
                return ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(w.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
