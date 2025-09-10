import 'package:flutter/material.dart';

import 'package:money_note/models/category_model.dart';

class CategoryDropdown extends StatelessWidget {
  final String? selectedId;
  final List<Category> categories;
  final void Function(String?) onChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedId,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: 'Select Category',
        border: OutlineInputBorder(),
      ),
      items:
          categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
      onChanged: onChanged,
    );
  }
}
