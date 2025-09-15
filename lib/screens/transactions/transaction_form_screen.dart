// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:money_note/utils/currency_formatter.dart';

import 'package:money_note/models/category_model.dart';
import 'package:money_note/models/wallet_model.dart';
import 'package:money_note/models/transaction_model.dart';

import 'package:money_note/services/transaction_service.dart';
import 'package:money_note/services/category_service.dart';
import 'package:money_note/services/wallet_service.dart';

import 'package:money_note/components/forms/transaction_type_selector.dart';
import 'package:money_note/components/forms/wallet_dropdown.dart';
import 'package:money_note/components/forms/category_dropdown.dart';
import 'package:money_note/components/forms/date_picker_field.dart';
import 'package:money_note/components/forms/currency_text_field.dart';
import 'package:money_note/components/alerts/flash_message.dart';
import 'package:money_note/components/buttons/submit_button.dart';

class TransactionFormScreen extends StatefulWidget {
  final String? transactionId;
  final TransactionModel? existingData;
  final VoidCallback? onSaved;
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
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedWalletId;

  List<Category> _categories = [];
  List<Wallet> _wallets = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _titleController.text = data.title;

      final formattedAmount = CurrencyFormatter().encode(data.amount);
      _amountController.value = TextEditingValue(
        text: formattedAmount,
        selection: TextSelection.collapsed(offset: formattedAmount.length),
      );

      _type = data.type;
      _selectedCategoryId = data.categoryId;
      _selectedWalletId = data.walletId;
      _selectedDate = data.date;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    CategoryService().getCategoryStream(type: _type).listen((list) {
      setState(() => _categories = list);
    });

    WalletService().getWalletStream().listen((list) {
      setState(() => _wallets = list);
    });
  }

  void _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose category and wallet first')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final title = _titleController.text.trim();
    // Remove all non-digit and non-decimal separator characters
    final amount = CurrencyFormatter().decodeAmount(_amountController.text);
    final trx = {
      'title': title,
      'amount': amount,
      'type': _type,
      'date': _selectedDate,
      'categoryId': _selectedCategoryId,
      'walletId': _selectedWalletId,
    };

    try {
      if (widget.transactionId != null) {
        await TransactionService().updateTransaction(
          widget.transactionId!,
          trx,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          FlashMessage(
            color: Colors.green,
            message: 'Transaction updated successfully',
          ),
        );
      } else {
        await TransactionService().addTransaction(trx);

        //clear the form
        _titleController.clear();
        _amountController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          FlashMessage(
            color: Colors.green,
            message: 'Transaction added successfully',
          ),
        );
      }

      if (widget.onSaved != null) {
        widget.onSaved!(); // trigger refresh di parent
      }

      // if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          FlashMessage(color: Colors.red, message: 'Transaction action failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false); // SELESAI LOADING
    }
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
                            _loadInitialData();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CategoryDropdown(
                        value: _selectedCategoryId,
                        type: _type,
                        onChanged:
                            (val) => setState(() => _selectedCategoryId = val),
                      ),

                      const SizedBox(height: 16),

                      WalletDropdown(
                        value:
                            _wallets.any(
                                  (wallet) => wallet.id == _selectedWalletId,
                                )
                                ? _selectedWalletId
                                : null,

                        onChanged:
                            (val) => setState(() => _selectedWalletId = val),
                      ),
                      const SizedBox(height: 16),
                      DatePickerField(
                        selectedDate: _selectedDate,
                        onDatePicked:
                            (picked) => setState(() => _selectedDate = picked),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Note is required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      CurrencyTextField(
                        controller: _amountController,
                        label: 'Amount',
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Amount is required'
                                    : null,
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
