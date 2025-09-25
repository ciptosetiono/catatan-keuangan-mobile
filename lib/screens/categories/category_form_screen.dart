import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:money_note/models/category_model.dart';
import 'package:money_note/services/firebase/category_service.dart';

import 'package:money_note/components/buttons/submit_button.dart';
import 'package:money_note/components/transactions/transaction_type_selector.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _nameController = TextEditingController();
  String _type = 'expense';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _type = widget.category!.type;
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final newCategory = Category(
      id: widget.category?.id ?? '',
      name: name,
      type: _type,
      userId: userId,
    );

    if (widget.category != null) {
      await _categoryService.updateCategory(newCategory);
    } else {
      await _categoryService.addCategory(newCategory);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Category' : 'Add Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TransactionTypeSelector(
              selected: _type,
              onChanged: (val) {
                setState(() {
                  _type = val;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: SubmitButton(
                isSubmitting: _isSubmitting,
                onPressed: _submit,
                label: isEdit ? 'Update' : 'Save',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
