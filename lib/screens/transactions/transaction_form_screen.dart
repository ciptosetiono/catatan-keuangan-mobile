import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../components/forms/transaction_type_selector.dart';
import '../../../components/forms/wallet_dropdown.dart';
import '../../../components/forms/date_picker_field.dart';

import '../../../services/transaction_service.dart';
import '../../../services/category_service.dart';

import '../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../models/wallet_model.dart';
import '../../../services/wallet_service.dart';
import '../../components/forms/currency_text_field.dart';
import '../../../utils/currency_formatter.dart';
import '../../../components/alerts/flash_message.dart';

class TransactionFormScreen extends StatefulWidget {
  final String? transactionId;
  final TransactionModel? existingData;

  const TransactionFormScreen({
    super.key,
    this.transactionId,
    this.existingData,
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    if (widget.existingData != null) {
      final data = widget.existingData!;
      _titleController.text = data.title;
      _amountController.text = data.amount.toString();
      _type = data.type;
      _selectedCategoryId = data.categoryId;
      _selectedWalletId = data.walletId;
      _selectedDate = data.date;
    }
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose category and wallet first')),
      );
      return;
    }

    final title = _titleController.text.trim();
    // Remove all non-digit and non-decimal separator characters
    final amount = CurrencyFormatter().decodeAmount(_amountController.text);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    final trx = {
      'title': title,
      'amount': amount,
      'type': _type,
      'date': _selectedDate,
      'categoryId': _selectedCategoryId,
      'walletId': _selectedWalletId,
      'userId': userId,
    };

    if (widget.transactionId != null) {
      await TransactionService().updateTransaction(widget.transactionId!, trx);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        FlashMessage(
          color: Colors.green,
          message: 'Transaction updated successfully',
        ),
      );
    } else {
      try {
        await TransactionService().addTransaction(
          title: title,
          amount: amount,
          type: _type,
          categoryId: _selectedCategoryId!,
          walletId: _selectedWalletId!,
          date: _selectedDate,
        );
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          FlashMessage(
            color: Colors.green,
            message: 'Transaction added successfully',
          ),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          FlashMessage(color: Colors.red, message: 'Transaction action failed'),
        );
        return;
      }
    }

    // ignore: use_build_context_synchronously
    Navigator.pop(context, true);
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

                      DropdownButtonFormField<String>(
                        value:
                            _categories.any(
                                  (cat) => cat.id == _selectedCategoryId,
                                )
                                ? _selectedCategoryId
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _categories
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  ),
                                )
                                .toList(),
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
                      const SizedBox(height: 32),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          label: const Text('Save Transaction'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.lightBlue,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
