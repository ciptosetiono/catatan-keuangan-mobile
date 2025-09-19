import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/utils/currency_input_formatter.dart';

import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/models/wallet_model.dart';

import 'package:money_note/services/transfer_service.dart';
import 'package:money_note/services/wallet_service.dart';

import 'package:money_note/components/wallets/wallet_dropdown.dart';
import 'package:money_note/components/forms/date_picker_field.dart';
import 'package:money_note/components/ui/alerts/flash_message.dart';
import 'package:money_note/components/buttons/submit_button.dart';

class TransferFormScreen extends StatefulWidget {
  final TransactionModel? transfer;

  const TransferFormScreen({super.key, this.transfer});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final _walletService = WalletService();
  final _transferService = TransferService();
  StreamSubscription<List<Wallet>>? _walletSubscription;

  Wallet? _fromWallet;
  Wallet? _toWallet;
  List<Wallet> _wallets = [];
  DateTime _selectedDate = DateTime.now();
  bool get isEdit => widget.transfer != null;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    if (isEdit) _initEditData();
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initEditData() async {
    final t = widget.transfer!;

    final formattedAmount = CurrencyFormatter().encode(t.amount);
    _amountController.value = TextEditingValue(
      text: formattedAmount,
      selection: TextSelection.collapsed(offset: formattedAmount.length),
    );

    _noteController.text = t.title;
    _selectedDate = t.date;

    _fromWallet = await _walletService.getWalletById(t.fromWalletId!);
    _toWallet = await _walletService.getWalletById(t.toWalletId!);
    if (mounted) {
      setState(() {});
    }
  }

  void _loadWallets() async {
    _walletSubscription = _walletService.getWalletStream().listen((list) {
      if (mounted) {
        setState(() => _wallets = list);
      }
    });
  }

  int _parseAmount(String val) {
    return int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (_fromWallet == null) {
        _showAlert('From Wallet is required');
        return;
      }

      if (_toWallet == null) {
        _showAlert('To Wallet is required');
        return;
      }

      if (_fromWallet!.id == _toWallet!.id) {
        _showAlert('Cannot transfer to the same wallet.');
        return;
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        _showAlert('User not authenticated.');
        return;
      }

      final amount = _parseAmount(_amountController.text);
      if (amount <= 0) {
        _showAlert('Amount is required');
        return;
      }

      if (_fromWallet!.currentBalance < amount && !isEdit) {
        _showAlert('Insufficient balance in source wallet.');
        return;
      }

      final note =
          _noteController.text.trim().isEmpty
              ? 'Transfer'
              : _noteController.text.trim();

      final transfer = TransactionModel(
        id: isEdit ? widget.transfer!.id : '',
        title: note,
        amount: amount.toDouble(),
        type: 'transfer',
        date: _selectedDate,
        userId: currentUserId,
        walletId: null,
        categoryId: null,
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
      );

      if (isEdit) {
        await _transferService.updateTransfer(widget.transfer!, transfer);
      } else {
        await _transferService.addTransfer(transfer);
      }

      if (!mounted) return;
      _showSuccessMessage();

      // ⛔️ Harus setelah semua selesai dan sebelum return
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showAlert(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAlert(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(FlashMessage(color: Colors.red, message: message));
    });
  }

  void _showSuccessMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        FlashMessage(
          color: Colors.green,
          message:
              isEdit
                  ? 'Transfer updated successfully'
                  : 'Transfer added successfully',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Transfer' : 'Transfer Funds')),
      body:
          _wallets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      WalletDropdown(
                        label: 'From Wallet',
                        value: _fromWallet?.id,
                        onChanged: (walletId) {
                          final wallet =
                              _wallets
                                  .where((w) => w.id == walletId)
                                  .cast<Wallet?>()
                                  .firstOrNull;
                          setState(() => _fromWallet = wallet);
                        },
                      ),

                      const SizedBox(height: 12),
                      WalletDropdown(
                        label: 'To Wallet',
                        value: _toWallet?.id,
                        onChanged: (walletId) {
                          final wallet =
                              _wallets
                                  .where((w) => w.id == walletId)
                                  .cast<Wallet?>()
                                  .firstOrNull;
                          setState(() => _toWallet = wallet);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        decoration: const InputDecoration(labelText: 'Amount'),
                        validator:
                            (val) =>
                                (val == null || val.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      DatePickerField(
                        selectedDate: _selectedDate,
                        onDatePicked:
                            (picked) => setState(() => _selectedDate = picked),
                      ),
                      const SizedBox(height: 24),
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
