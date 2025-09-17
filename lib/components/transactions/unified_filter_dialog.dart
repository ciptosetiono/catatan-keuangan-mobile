import 'package:flutter/material.dart';
import 'package:money_note/components/transactions/transaction_type_selector.dart';
import 'package:money_note/components/wallets/wallet_dropdown.dart';
import 'package:money_note/components/forms/category_dropdown.dart';

class UnifiedFilterDialog extends StatefulWidget {
  final String? typeFilter;
  final String? walletFilter;
  final String? categoryFilter;
  final String? titleFilter;
  final void Function({
    String? type,
    String wallet,
    String? category,
    String? title,
  })
  onFilterApplied;

  const UnifiedFilterDialog({
    super.key,
    required this.typeFilter,
    required this.walletFilter,
    required this.categoryFilter,
    required this.titleFilter,
    required this.onFilterApplied,
  });

  @override
  State<UnifiedFilterDialog> createState() => _UnifiedFilterDialogState();
}

class _UnifiedFilterDialogState extends State<UnifiedFilterDialog> {
  String? _type;
  String? _wallet;
  String? _category;
  String? _title;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.typeFilter;
    _wallet = widget.walletFilter;
    _category = widget.categoryFilter;
    _title = widget.titleFilter;
    _titleController.text = _title ?? '';
  }

  void _resetFilters() {
    setState(() {
      _type = null;
      _category = null;
      _title = null;
      _titleController.clear();
    });
    Navigator.pop(context);
    widget.onFilterApplied(type: null, category: null, title: null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header tanpa margin
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            TransactionTypeSelector(
              selected: _type,
              onChanged: (val) {
                setState(() {
                  _type = val;
                  _category = null;
                });
              },
            ),

            const SizedBox(height: 20),
            CategoryDropdown(
              value: _category,
              type: _type,
              onChanged: (val) => setState(() => _category = val),
            ),
            const SizedBox(height: 20),
            WalletDropdown(
              value: _wallet,
              onChanged: (val) => setState(() => _wallet = val),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Note',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged:
                  (val) =>
                      setState(() => _title = val.trim().isEmpty ? null : val),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ), // lebih besar
                    textStyle: const TextStyle(
                      fontSize: 16,
                    ), // ukuran font lebih besar
                  ),
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onFilterApplied(
                      type: _type,
                      category: _category,
                      title: _title,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ), // lebih besar
                    textStyle: const TextStyle(
                      fontSize: 16,
                    ), // font lebih besar
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
