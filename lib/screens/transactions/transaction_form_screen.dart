// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:money_note/utils/currency_formatter.dart';
import 'package:money_note/models/category_model.dart';
import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/models/transaction_model.dart';
import 'package:money_note/services/sqlite/transaction_service.dart';
import 'package:money_note/services/sqlite/category_service.dart';
import 'package:money_note/services/sqlite/wallet_service.dart';
import 'package:money_note/services/setting_preferences_service.dart';
import 'package:money_note/components/transactions/transaction_type_selector.dart';
import 'package:money_note/components/wallets/wallet_dropdown.dart';
import 'package:money_note/components/categories/category_dropdown.dart';
import 'package:money_note/components/forms/date_picker_field.dart';
import 'package:money_note/components/forms/currency_text_field.dart';
import 'package:money_note/components/ui/alerts/flash_message.dart';
import 'package:money_note/components/buttons/submit_button.dart';

class TransactionFormScreen extends StatefulWidget {
  final String? transactionId;
  final TransactionModel? existingData;
  final void Function(TransactionModel)? onSaved;

  const TransactionFormScreen({
    super.key,
    this.transactionId,
    this.existingData,
    this.onSaved,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _mode = 'add';
  String _type = 'expense';

  String? _selectedWalletId;
  List<Wallet> _wallets = [];

  String? _selectedCategoryId;
  List<Category> _categories = [];

  DateTime _selectedDate = DateTime.now();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
    _loadDefaultData();
  }

  Future<void> _loadDefaultData() async {
    final prefs = SettingPreferencesService();

    if (widget.existingData != null) {
      _initializeEditMode(widget.existingData!);
    } else {
      await _initializeDefaultMode(prefs);
    }
  }

  void _initializeEditMode(TransactionModel data) {
    _mode = 'edit';
    _titleController.text = data.title;

    final formattedAmount = CurrencyFormatter().encode(data.amount);
    _amountController.text = formattedAmount;

    _type = data.type;
    _selectedCategoryId = data.categoryId;
    _selectedWalletId = data.walletId;
    _selectedDate = data.date;
  }

  Future<void> _initializeDefaultMode(SettingPreferencesService prefs) async {
    _mode = 'add';
    final defaultWalletId = await prefs.getDefaultWallet();
    final defaultCategoryId = await prefs.getDefaultCategory(type: _type);

    setState(() {
      _selectedWalletId = defaultWalletId;
      _selectedCategoryId = defaultCategoryId;
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _loadMasterData() async {
    CategoryService().getCategoryStream(type: _type).listen((list) {
      if (!mounted) return;
      setState(() => _categories = list);
    });

    WalletService().getWalletStream().listen((list) {
      if (!mounted) return;
      setState(() => _wallets = list);
    });
  }

  void _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose wallet first')));
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose category first')));
      return;
    }

    final amount = CurrencyFormatter().decodeAmount(_amountController.text);
    final title = _titleController.text.trim();

    setState(() => _isSubmitting = true);

    final trx = {
      'type': _type,
      'walletId': _selectedWalletId,
      'categoryId': _selectedCategoryId,
      'amount': amount,
      'date': _selectedDate.toIso8601String(),
      'title': title,
    };

    try {
      TransactionModel? savedTransaction;

      if (widget.transactionId != null) {
        savedTransaction = await TransactionService().updateTransaction(
          widget.transactionId!,
          trx,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          FlashMessage(
            color: Colors.green,
            message: 'Transaction updated successfully!',
          ),
        );
      } else {
        savedTransaction = await TransactionService().addTransaction(trx);

        _titleController.clear();
        _amountController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          FlashMessage(
            color: Colors.green,
            message: 'Transaction added successfully',
          ),
        );
      }

      if (widget.onSaved != null && savedTransaction != null) {
        widget.onSaved!(savedTransaction);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        FlashMessage(
          color: Colors.red,
          message: 'Transaction action failed $e',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? validateAmount(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = CurrencyFormatter().decodeAmount(val);
    final wallet = _wallets.firstWhere((w) => w.id == _selectedWalletId);
    final availableBalance =
        _type == 'expense' && _mode == 'edit'
            ? wallet.currentBalance + widget.existingData!.amount
            : wallet.currentBalance;

    if (_type == 'expense' && amount > availableBalance) {
      return 'Amount exceeds wallet balance';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transactionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body:
          _categories.isEmpty || _wallets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TransactionTypeSelector(
                        selected: _type,
                        onChanged: (val) {
                          setState(() {
                            _type = val;
                            _selectedCategoryId = null;
                            _loadDefaultData();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      WalletDropdown(
                        value: _selectedWalletId,
                        onChanged: (val) {
                          print(' $val');
                          setState(() => _selectedWalletId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DatePickerField(
                        selectedDate: _selectedDate,
                        onDatePicked: (picked) {
                          print('Selected Date: $picked');
                          setState(() => _selectedDate = picked);
                        },
                      ),
                      const SizedBox(height: 16),
                      CategoryDropdown(
                        value: _selectedCategoryId,
                        type: _type,
                        onChanged: (val) {
                          print('Selected Category ID: $val');
                          setState(() => _selectedCategoryId = val);
                        },
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),
                      CurrencyTextField(
                        controller: _amountController,
                        label: 'Amount',
                        validator: validateAmount,
                      ),
                      const SizedBox(height: 16),
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
