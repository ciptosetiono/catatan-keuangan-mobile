// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/wallet_model.dart';
import '../../services/sqlite/wallet_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/currency_input_formatter.dart';
import '../../../components/buttons/submit_button.dart';
import 'package:money_note/services/ad_service.dart';
import 'package:money_note/components/ui/alerts/flash_message.dart';

class WalletFormScreen extends StatefulWidget {
  final Wallet? wallet;
  final bool showAds; // 👈 tambahkan opsi ini agar bisa kontrol iklan dari luar

  const WalletFormScreen({super.key, this.wallet, this.showAds = true});

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _walletService = WalletService();
  bool _isSubmitting = false;
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
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balance = _parseCurrency(_balanceController.text);
    final userId = '1';

    int oldStartBalance = (widget.wallet?.startBalance ?? 0).toInt();
    int oldCurrentBalance = (widget.wallet?.currentBalance ?? 0).toInt();
    int currentBalance =
        isEdit ? oldCurrentBalance + (balance - oldStartBalance) : balance;

    if (currentBalance < 0) {
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Invalid Balance'),
              content: const Text(
                'Current balance can not be negative.\nPlease check the Start Balance.',
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

    Wallet? resultWallet;

    if (isEdit) {
      final updatedWallet = Wallet(
        id: widget.wallet!.id,
        userId: userId,
        name: name,
        startBalance: balance.toDouble(),
        currentBalance: currentBalance.toDouble(),
        createdAt: widget.wallet!.createdAt,
      );
      resultWallet = await _walletService.updateWallet(updatedWallet);
    } else {
      // Add new wallet
      resultWallet = await _walletService.addWallet(
        Wallet(
          id: '', // SQLite akan generate ID atau kita ambil terakhir
          userId: userId,
          name: name,
          startBalance: balance.toDouble(),
          currentBalance: currentBalance.toDouble(),
          createdAt: DateTime.now(),
        ),
      );
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      FlashMessage(color: Colors.green, message: 'Wallet saved successfully'),
    );

    Navigator.pop(context, resultWallet); // ✅ kirim wallet ke dropdown

    // ✅ return wallet ke halaman sebelumnya (misalnya ke TransactionForm)
    /*
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (widget.showAds) {
        AdService.showInterstitialAd();
        await Future.delayed(const Duration(seconds: 2));
      }
      Navigator.pop(context, wallet);
    });
    */
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
                decoration: const InputDecoration(
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
                decoration: const InputDecoration(
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
              SizedBox(
                width: double.infinity,
                child: SubmitButton(
                  isSubmitting: _isSubmitting,
                  onPressed: _submit,
                  label: isEdit ? 'Update' : 'Save',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
