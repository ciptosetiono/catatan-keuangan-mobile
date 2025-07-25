import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/currency_input_formatter.dart';

class WalletFormScreen extends StatefulWidget {
  final Wallet? wallet;

  const WalletFormScreen({super.key, this.wallet});

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _walletService = WalletService();

  bool get isEdit => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameController.text = widget.wallet!.name;
      _balanceController.text = CurrencyFormatter().encode(
        widget.wallet!.startBalance,
      );
    }
  }

  /// Parse currency string to int
  int _parseCurrency(String value) {
    final numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numericString) ?? 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balance = _parseCurrency(_balanceController.text);
    final userId = FirebaseAuth.instance.currentUser!.uid;

    int oldStartBalance = (widget.wallet?.startBalance ?? 0).toInt();
    int oldCurrentBalance = (widget.wallet?.currentBalance ?? 0).toInt();
    int currentBalance =
        isEdit ? oldCurrentBalance + (balance - oldStartBalance) : balance;

    // ⚠️ Cek jika hasil currentBalance negatif
    if (currentBalance < 0) {
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Invalid Balance'),
              content: const Text(
                'Current balance tidak boleh negatif.\nSilakan periksa nilai saldo awal.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    final wallet = Wallet(
      id: widget.wallet?.id ?? '',
      userId: userId,
      name: name,
      icon: 'wallet',
      color: '#2196F3',
      startBalance: balance,
      currentBalance: currentBalance,
      createdAt: widget.wallet?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      await _walletService.updateWallet(wallet);
    } else {
      await _walletService.addWallet(wallet);
    }

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Wallet' : 'Add Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Wallet Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Start Balance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: Icon(isEdit ? Icons.save : Icons.add),
                    label: Text(isEdit ? 'Save Changes' : 'Add Wallet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
