// ignore_for_file: use_build_context_synchronously, avoid_print
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
    _loadMasterDataAndDefaults();
  }

  Future<void> _loadMasterDataAndDefaults() async {
    final prefs = SettingPreferencesService();

    _wallets = await WalletService().getWalletStream().first;
    _categories = await CategoryService().getCategoryStream(type: _type).first;

    if (widget.existingData != null) {
      _initializeEditMode(widget.existingData!);
    } else {
      _initializeDefaultMode(prefs);
    }

    if (!mounted) return;
    setState(() {});
  }

  void _initializeEditMode(TransactionModel data) {
    _mode = 'edit';
    _titleController.text = data.title;
    _amountController.text = CurrencyFormatter().encode(data.amount);
    _type = data.type;
    _selectedWalletId = data.walletId;
    _selectedCategoryId = data.categoryId;
    _selectedDate = data.date;
  }

  Future<void> _initializeDefaultMode(SettingPreferencesService prefs) async {
    _mode = 'add';
    final defaultWalletId = await prefs.getDefaultWallet();
    final defaultCategoryId = await prefs.getDefaultCategory(type: _type);

    setState(() {
      if (_wallets.any((w) => w.id == defaultWalletId)) {
        _selectedWalletId = defaultWalletId;
      } else if (_wallets.isNotEmpty) {
        _selectedWalletId = _wallets.first.id;
      }

      if (_categories.any((c) => c.id == defaultCategoryId)) {
        _selectedCategoryId = defaultCategoryId;
      } else if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }

      _selectedDate = DateTime.now();
    });
  }

  void _onTypeChanged(String val) async {
    if (_type == val) return;
    setState(() {
      _type = val;
      _selectedCategoryId = null;
    });

    _categories = await CategoryService().getCategoryStream(type: _type).first;
    final prefs = SettingPreferencesService();
    final defaultCategoryId = await prefs.getDefaultCategory(type: _type);

    if (_categories.any((c) => c.id == defaultCategoryId)) {
      _selectedCategoryId = defaultCategoryId;
    } else if (_categories.isNotEmpty) {
      _selectedCategoryId = _categories.first.id;
    }

    if (!mounted) return;
    setState(() {});
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

      if (_mode == 'edit') {
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
    if (val == null || val.trim().isEmpty) return 'Amount is required';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TransactionTypeSelector(
                selected: _type,
                onChanged: _onTypeChanged,
              ),
              const SizedBox(height: 16),
              WalletDropdown(
                value: _selectedWalletId,
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),
              const SizedBox(height: 16),
              DatePickerField(
                selectedDate: _selectedDate,
                onDatePicked:
                    (picked) => setState(() => _selectedDate = picked),
              ),
              const SizedBox(height: 16),
              CategoryDropdown(
                value: _selectedCategoryId,
                type: _type,
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter note',
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
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CurrencyTextField(
                controller: _amountController,
                label: 'Amount',
                validator: validateAmount,
              ),
              const SizedBox(height: 24),

              // === BUTTONS ROW (SAVE + CANCEL) ===
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.grey[800],
                        side: BorderSide(color: Colors.grey.shade400),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            _type == 'income' ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _type == 'income'
                                    ? 'Save Income'
                                    : 'Save Expense',
                              ),
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
