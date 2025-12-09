// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/services/sqlite/transfer_service.dart';
import 'package:money_note/services/sqlite/wallet_service.dart';
import 'package:money_note/components/wallets/wallet_dropdown.dart';
import 'package:money_note/components/forms/date_picker_field.dart';
import 'package:money_note/components/forms/currency_text_field.dart';
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
  final _transferService = TransferService();

  String? _fromWalletId;
  String? _toWalletId;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  bool get isEdit => widget.transfer != null;

  /// Flag untuk mencegah reset dropdown saat StreamBuilder rebuild
  bool _walletInitialized = false;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      _initializeEditMode();
    }
  }

  Future<void> _initializeEditMode() async {
    final t = widget.transfer!;
    _amountController.text = await CurrencyFormatter().encode(t.amount);
    _selectedDate = t.date;

    // Ini hanya assignment pertama
    _fromWalletId = t.fromWalletId;
    _toWalletId = t.toWalletId;

    _walletInitialized = true; // untuk mode edit
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Wallet> wallets) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_fromWalletId == null) {
      _showAlert('From Wallet is required');
      return;
    }
    if (_toWalletId == null) {
      _showAlert('To Wallet is required');
      return;
    }
    if (_fromWalletId == _toWalletId) {
      _showAlert('Cannot transfer to the same wallet.');
      return;
    }

    final amount = CurrencyFormatter().decodeAmount(_amountController.text);
    if (amount <= 0) {
      _showAlert('Amount is required');
      return;
    }

    final fromWallet = wallets.firstWhere((w) => w.id == _fromWalletId);
    final toWallet = wallets.firstWhere((w) => w.id == _toWalletId);

    if (!isEdit && fromWallet.currentBalance < amount) {
      _showAlert('Insufficient balance in source wallet.');
      return;
    }

    final transferData = {
      'title': 'Transfer from ${fromWallet.name} to ${toWallet.name}',
      'amount': amount.toDouble(),
      'type': 'transfer',
      'date': _selectedDate.toIso8601String(),
      'walletId': fromWallet.id,
      'fromWalletId': fromWallet.id,
      'toWalletId': toWallet.id,
    };

    setState(() => _isSubmitting = true);

    try {
      if (isEdit) {
        await _transferService.updateTransfer(
          widget.transfer!.id,
          transferData,
        );
      } else {
        await _transferService.addTransfer(transferData);
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

      Navigator.pop(context, isEdit ? 'updated' : 'added');
    } catch (e) {
      if (!mounted) return;
      _showAlert('Transfer failed!');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Transfer' : 'Transfer Funds')),
      body: StreamBuilder<List<Wallet>>(
        stream: WalletService().getWalletStream(),
        builder: (context, snapshot) {
          final wallets = snapshot.data ?? [];

          if (wallets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // ---- DEFAULT WALLET SET ONLY ONCE ----
          if (!_walletInitialized) {
            if (isEdit) {
              // Sudah di-set dari initState, tidak lakukan apa-apa
            } else {
              // ADD mode default selection
              _fromWalletId = wallets.first.id;
              _toWalletId =
                  wallets.length > 1 ? wallets[1].id : wallets.first.id;
            }

            _walletInitialized = true;
          }
          // ----------------------------------------

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  WalletDropdown(
                    label: 'From Wallet',
                    value: _fromWalletId,
                    onChanged: (val) => setState(() => _fromWalletId = val),
                  ),
                  const SizedBox(height: 12),

                  WalletDropdown(
                    label: 'To Wallet',
                    value: _toWalletId,
                    onChanged: (val) => setState(() => _toWalletId = val),
                  ),
                  const SizedBox(height: 12),

                  CurrencyTextField(
                    controller: _amountController,
                    label: 'Amount',
                    validator:
                        (val) =>
                            val == null || val.trim().isEmpty
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
                      onPressed: () => _submit(wallets),
                      label: isEdit ? 'Update' : 'Save',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
