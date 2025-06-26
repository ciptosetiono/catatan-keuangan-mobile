import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import '../../../services/category_service.dart';

class UnifiedFilterDialog extends StatefulWidget {
  final String? typeFilter;
  final String? categoryFilter;
  final String? titleFilter;
  final void Function({String? type, String? category, String? title})
  onFilterApplied;

  const UnifiedFilterDialog({
    Key? key,
    required this.typeFilter,
    required this.categoryFilter,
    required this.titleFilter,
    required this.onFilterApplied,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Tambahan'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pemasukan'),
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
                    label: const Text('Pengeluaran'),
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
            StreamBuilder<List<Category>>(
              stream: CategoryService().getCategoryStream(type: _type),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  isExpanded: true,
                  items:
                      items
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.name,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _category = val),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
              onChanged:
                  (val) =>
                      setState(() => _title = val.trim().isEmpty ? null : val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // cancel
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onFilterApplied(
              type: _type,
              category: _category,
              title: _title,
            );
          },
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}
