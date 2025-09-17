import 'package:flutter/material.dart';

import 'package:money_note/components/categories/category_delete_dialog.dart';
import 'package:money_note/models/category_model.dart';
import 'package:money_note/screens/categories/category_form_screen.dart';

Future<void> showCategoryBottomsheetMenu({
  required BuildContext context,
  required Category category,
  void Function()? onCategoryUpdated,
  void Function()? onCategoryDeleted,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.green),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context); // tutup bottomsheet
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryFormScreen(category: category),
                  ),
                );

                if (result == true) {
                  if (onCategoryUpdated != null) {
                    onCategoryUpdated();
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () async {
                await confirmAndDeleteCategory(
                  context: context,
                  categoryId: category.id,
                  onDeleted: () {
                    Navigator.pop(context); // tutup bottomsheet
                    if (onCategoryDeleted != null) {
                      onCategoryDeleted();
                    }
                  },
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
