import 'package:flutter/material.dart';

import 'package:money_note/models/category_model.dart';
import 'package:money_note/services/category_service.dart';

class CategoryDropdown extends StatelessWidget {
  final String? type;
  final String? value;
  final String? placeholder;
  final void Function(String?) onChanged;

  const CategoryDropdown({
    super.key,
    this.type,
    required this.value,
    this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: CategoryService().getCategoryStream(type: type),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            labelText: 'Select Category',
            border: OutlineInputBorder(),
          ),
          items:
              items
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
