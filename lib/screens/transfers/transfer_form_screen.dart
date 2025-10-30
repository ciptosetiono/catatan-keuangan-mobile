import 'package:flutter/material.dart';
import 'dart:async';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/models/goal_model.dart';

import 'package:money_note/services/sqlite/transfer_service.dart';
import 'package:money_note/services/sqlite/wallet_service.dart';
import 'package:money_note/services/sqlite/goal_service.dart';

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

  final _walletService = WalletService();
  final _transferService = TransferService();
  final _goalService = GoalService();

  StreamSubscription<List<Wallet>>? _walletSubscription;
  StreamSubscription<List<GoalModel>>? _goalSubscription;

  Wallet? _fromWallet;
  Wallet? _toWallet;
  List<Wallet> _wallets = [];

  GoalModel? _selectedGoal;
  List<GoalModel> _goals = [];

  DateTime _selectedDate = DateTime.now();
  bool get isEdit => widget.transfer != null;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadGoals();
    if (isEdit) _initEditData();
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _goalSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _initEditData() async {
    final t = widget.transfer!;

    final formattedAmount = await CurrencyFormatter().encode(t.amount);
    _amountController.value = TextEditingValue(
      text: formattedAmount,
      selection: TextSelection.collapsed(offset: formattedAmount.length),
    );

    _selectedDate = t.date;

    _fromWallet = await _walletService.getWalletById(t.fromWalletId!);
    _toWallet = await _walletService.getWalletById(t.toWalletId!);

    if (t.goalId != null) {
      _selectedGoal = _goals.firstWhereOrNull((g) => g.id == t.goalId);
    }

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

  void _loadGoals() async {
    _goalSubscription = _goalService.getGoalStream().listen((list) {
      if (mounted) setState(() => _goals = list);
    });
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

      final amount = CurrencyFormatter().decodeAmount(_amountController.text);
      if (amount <= 0) {
        _showAlert('Amount is required');
        return;
      }

      if (_fromWallet!.currentBalance < amount && !isEdit) {
        _showAlert('Insufficient balance in source wallet.');
        return;
      }

      final title = 'Transfer from ${_fromWallet!.name} to ${_toWallet!.name}';

      final transfer = {
        'title': title,
        'amount': amount.toDouble(),
        'type': 'transfer',
        'date': _selectedDate.toIso8601String(),
        'categoryId': null,
        'walletId': _fromWallet!.id, //set fromWalletId
        'fromWalletId': _fromWallet!.id,
        'toWalletId': _toWallet!.id,
        'goalId': _selectedGoal?.id,
        'isGoalTransfer': _selectedGoal != null,
      };

      if (isEdit) {
        await _transferService.updateTransfer(widget.transfer!.id, transfer);
      } else {
        await _transferService.addTransfer(transfer);
      }

      if (!mounted) return;
      _showSuccessMessage();

      // ⛔️ Harus setelah semua selesai dan sebelum return
      //Navigator.pop(context);
      Navigator.pop(context, isEdit ? 'updated' : 'added');
    } catch (e) {
      if (mounted) {
        _showAlert('Transfer failed!');
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
                      CurrencyTextField(
                        controller: _amountController,
                        label: 'Amount',
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
                      /*

                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Goal (Optional)',
                        ),
                        // ignore: deprecated_member_use
                        value: _selectedGoal?.id,
                        items:
                            _goals
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g.id,
                                    child: Text(
                                      '${g.name} (${g.currentAmount.toStringAsFixed(0)}/${g.targetAmount.toStringAsFixed(0)})',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGoal = _goals.firstWhereOrNull(
                              (g) => g.id == value,
                            );
                          });
                        },
                      ),
                      */
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
