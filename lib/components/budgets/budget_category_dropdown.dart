import 'package:flutter/material.dart';

import 'package:money_note/models/category_model.dart';

class BudgetCategoryDropdown extends StatelessWidget {
  final String selectedCategoryId;
  final List<Category> categories;
  final ValueChanged<String> onChanged;

  const BudgetCategoryDropdown({
    super.key,
    required this.selectedCategoryId,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedCategoryId,
            isExpanded: true,
            icon: const Icon(Icons.category),
            items: [
              const DropdownMenuItem(value: '', child: Text('All Categories')),
              ...categories.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ),
    );
  }
}
