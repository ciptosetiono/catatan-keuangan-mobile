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
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type selector
            const Text("Type", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      'Income',
                      style: TextStyle(
                        color: _type == 'income' ? Colors.white : Colors.black,
                      ),
                    ),
                    selected: _type == 'income',
                    selectedColor: Colors.green,
                    onSelected:
                        (selected) =>
                            setState(() => _type = selected ? 'income' : null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      'Expense',
                      style: TextStyle(
                        color: _type == 'expense' ? Colors.white : Colors.black,
                      ),
                    ),
                    selected: _type == 'expense',
                    selectedColor: Colors.red,
                    onSelected:
                        (selected) =>
                            setState(() => _type = selected ? 'expense' : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category dropdown
            StreamBuilder<List<Category>>(
              stream: CategoryService().getCategoryStream(type: _type),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                final validCategoryIds = items.map((e) => e.id).toSet();
                if (_category != null &&
                    !validCategoryIds.contains(_category)) {
                  _category = null;
                }

                return DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
            const SizedBox(height: 20),

            // Title input
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
