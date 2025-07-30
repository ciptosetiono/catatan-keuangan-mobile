import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';

import '../../services/transfer_service.dart';
import '../../services/wallet_service.dart';

import '../../utils/currency_formatter.dart';
import '../../utils/currency_input_formatter.dart';

import '../../../components/forms/date_picker_field.dart';
import '../../../components/alerts/flash_message.dart';
import '../../../components/buttons/submit_button.dart';

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
      if (!_formKey.currentState!.validate() ||
          _fromWallet == null ||
          _toWallet == null)
        return;

      final amount = _parseAmount(_amountController.text);
      final note =
          _noteController.text.trim().isEmpty
              ? 'Transfer'
              : _noteController.text.trim();

      if (_fromWallet!.id == _toWallet!.id) {
        _showAlert('Cannot transfer to the same wallet.');
        return;
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        _showAlert('User not authenticated.');
        return;
      }

      if (_fromWallet!.currentBalance < amount && !isEdit) {
        _showAlert('Insufficient balance in source wallet.');
        return;
      }

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

      ScaffoldMessenger.of(context).showSnackBar(
        FlashMessage(
          color: Colors.green,
          message:
              isEdit
                  ? 'Transfer updated successfully'
                  : 'Transfer added successfully',
        ),
      );

      // ⛔️ Harus setelah semua selesai dan sebelum return
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(FlashMessage(color: Colors.red, message: e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Warning'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
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
                      DropdownButtonFormField<Wallet>(
                        value: _fromWallet,
                        items:
                            _wallets
                                .map(
                                  (wallet) => DropdownMenuItem(
                                    value: wallet,
                                    child: Text(wallet.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _fromWallet = val),
                        decoration: const InputDecoration(
                          labelText: 'From Wallet',
                        ),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Wallet>(
                        value: _toWallet,
                        items:
                            _wallets
                                .map(
                                  (wallet) => DropdownMenuItem(
                                    value: wallet,
                                    child: Text(wallet.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _toWallet = val),
                        decoration: const InputDecoration(
                          labelText: 'To Wallet',
                        ),
                        validator: (val) => val == null ? 'Required' : null,
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
                          SubmitButton(
                            isSubmitting: _isSubmitting,
                            onPressed: _isSubmitting ? () => {} : _submit,
                            label: isEdit ? 'Update Transfer' : 'Add Transfer',
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
