// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:math';
// ignore: unused_import
import 'package:money_note/services/ad_service.dart';
import '../../services/sqlite/wallet_service.dart';
import '../../models/wallet_model.dart';
import 'package:money_note/components/forms/currency_text_field.dart';
import '../../utils/currency_formatter.dart';
import '../../../components/buttons/submit_button.dart';
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
      _initAmountInput();
    }
  }

  Future<void> _initAmountInput() async {
    _nameController.text = widget.wallet!.name;
    _balanceController.text = await CurrencyFormatter().encode(
      widget.wallet!.startBalance,
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    // ignore: await_only_futures
    final balance = await CurrencyFormatter().decodeAmount(
      _balanceController.text,
    );

    final userId = '1';

    final double oldStartBalance = widget.wallet?.startBalance ?? 0;
    final double oldCurrentBalance = widget.wallet?.currentBalance ?? 0;
    final double currentBalance =
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

    //display intertitials ads
    if (widget.showAds == true) {
      final random = Random();
      // ~33% chance to show ad
      if (random.nextInt(3) == 0) {
        Future.delayed(const Duration(seconds: 1), () {
          AdService.showInterstitialAd();
        });
      }
    }
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter wallet name',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),

                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              CurrencyTextField(
                controller: _balanceController,
                label: 'Start Balance',
                placeholder: 'Enter Start Balance',
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
