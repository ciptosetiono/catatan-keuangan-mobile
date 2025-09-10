import 'package:flutter/material.dart';

import 'package:money_note/models/category_model.dart';

import 'package:money_note/services/category_service.dart';

class UnifiedFilterDialog extends StatefulWidget {
  final String? typeFilter;
  final String? categoryFilter;
  final String? titleFilter;
  final void Function({String? type, String? category, String? title})
  onFilterApplied;

  const UnifiedFilterDialog({
    super.key,
    required this.typeFilter,
    required this.categoryFilter,
    required this.titleFilter,
    required this.onFilterApplied,
  });

  @override
  State<UnifiedFilterDialog> createState() => _UnifiedFilterDialogState();
}

class _UnifiedFilterDialogState extends State<UnifiedFilterDialog> {
  String? _type;
  String? _category;
  String? _title;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.typeFilter;
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Search Transactions'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type selector
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Income'),
                    selected: _type == 'income',
                    selectedColor: Colors.green.shade100,
                    onSelected:
                        (selected) =>
                            setState(() => _type = selected ? 'income' : null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Expense'),
                    selected: _type == 'expense',
                    selectedColor: Colors.red.shade100,
                    onSelected:
                        (selected) =>
                            setState(() => _type = selected ? 'expense' : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category dropdown
            StreamBuilder<List<Category>>(
              stream: CategoryService().getCategoryStream(type: _type),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];

                // Ensure selected category exists in current list
                final validCategoryIds = items.map((e) => e.id).toSet();
                if (_category != null &&
                    !validCategoryIds.contains(_category)) {
                  _category = null;
                }
                return DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  isExpanded: true,
                  items:
                      items
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _category = val),
                );
              },
            ),
            const SizedBox(height: 16),

            // Title input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Note'),
              onChanged:
                  (val) =>
                      setState(() => _title = val.trim().isEmpty ? null : val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _resetFilters, child: const Text('Reset')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onFilterApplied(
              type: _type,
              category: _category,
              title: _title,
            );
          },
          child: const Text('Apply'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
