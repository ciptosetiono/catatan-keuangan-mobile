// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../services/sqlite/wallet_service.dart';
import '../../services/sqlite/category_service.dart';
import '../../services/setting_preferences_service.dart';
import '../../models/wallet_model.dart';
import '../../models/category_model.dart';
import 'package:money_note/components/ui/alerts/flash_message.dart';

class DefaultSettingsScreen extends StatefulWidget {
  const DefaultSettingsScreen({super.key});

  @override
  State<DefaultSettingsScreen> createState() => _DefaultSettingsScreenState();
}

class _DefaultSettingsScreenState extends State<DefaultSettingsScreen> {
  List<Wallet> wallets = [];
  String? selectedWalletId;

  List<Category> incomeCategories = [];
  String? selectedIncomeCategoryId;

  List<Category> expenseCategories = [];
  String? selectedExpenseCategoryId;

  bool isLoading = true;
  bool isSaving = false;

  final _prefs = SettingPreferencesService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final walletList = await WalletService().getWallets();
    final savedWalletId = await _prefs.getDefaultWallet();

    final incomeCategoryList = await CategoryService().getCategories(
      type: 'income',
    );
    final savedIncomeCategoryId = await _prefs.getDefaultCategory(
      type: 'income',
    );

    final expenseCategoryList = await CategoryService().getCategories(
      type: 'expense',
    );
    final savedExpenseCategoryId = await _prefs.getDefaultCategory(
      type: 'expense',
    );

    setState(() {
      wallets = walletList;
      selectedWalletId =
          savedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null);

      incomeCategories = incomeCategoryList;
      selectedIncomeCategoryId =
          savedIncomeCategoryId ??
          (incomeCategories.isNotEmpty ? incomeCategories.first.id : null);

      expenseCategories = expenseCategoryList;
      selectedExpenseCategoryId =
          savedExpenseCategoryId ??
          (expenseCategories.isNotEmpty ? expenseCategories.first.id : null);

      isLoading = false;
    });
  }

  Future<void> _saveAll() async {
    if (selectedWalletId == null ||
        selectedIncomeCategoryId == null ||
        selectedExpenseCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select all default settings.')),
      );
      return;
    }

    setState(() => isSaving = true);

    await _prefs.setDefaultWallet(selectedWalletId!);
    await _prefs.setDefaultCategory(
      categoryId: selectedIncomeCategoryId!,
      type: 'income',
    );
    await _prefs.setDefaultCategory(
      categoryId: selectedExpenseCategoryId!,
      type: 'expense',
    );

    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      FlashMessage(color: Colors.green, message: 'Category saved successfully'),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Icon(icon, color: Colors.teal.shade400, size: 22),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Default Settings'), elevation: 0),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingCard(
                      title: 'Default Wallet',
                      icon: Icons.account_balance_wallet_outlined,
                      child: DropdownButtonFormField<String>(
                        value: selectedWalletId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Choose Wallet',
                        ),
                        items:
                            wallets.map((wallet) {
                              return DropdownMenuItem(
                                value: wallet.id,
                                child: Text(wallet.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedWalletId = value);
                          }
                        },
                      ),
                    ),
                    _buildSettingCard(
                      title: 'Default Income Category',
                      icon: Icons.arrow_downward_rounded,
                      child: DropdownButtonFormField<String>(
                        value: selectedIncomeCategoryId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Choose Income Category',
                        ),
                        items:
                            incomeCategories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedIncomeCategoryId = value);
                          }
                        },
                      ),
                    ),
                    _buildSettingCard(
                      title: 'Default Expense Category',
                      icon: Icons.arrow_upward_rounded,
                      child: DropdownButtonFormField<String>(
                        value: selectedExpenseCategoryId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Choose Expense Category',
                        ),
                        items:
                            expenseCategories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedExpenseCategoryId = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSaving ? null : _saveAll,
                      child:
                          isSaving
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Save Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white, // white text
                                ),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}
