import 'package:flutter/material.dart';
import 'dart:math';
import 'package:money_note/models/category_model.dart';
import 'package:money_note/services/sqlite/category_service.dart';
import 'package:money_note/components/buttons/submit_button.dart';
import 'package:money_note/components/transactions/transaction_type_selector.dart';
import 'package:money_note/services/ad_service.dart';
import 'package:money_note/components/ui/alerts/flash_message.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  final String? defaultType;
  final bool? showAds;

  const CategoryFormScreen({
    super.key,
    this.category,
    this.defaultType,
    this.showAds = true,
  });

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

    if (widget.defaultType != null) {
      _type = widget.defaultType!;
    }

    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _type = widget.category!.type;
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);

    Category? resultCategory;

    if (widget.category != null) {
      // Update existing category
      final updatedCategory = Category(
        id: widget.category!.id,
        name: name,
        type: _type,
      );
      resultCategory = await _categoryService.updateCategory(updatedCategory);
    } else {
      resultCategory = await _categoryService.addCategory(
        Category(id: '', name: name, type: _type),
      );
    }

    if (!mounted) return;

    // ✅ Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      FlashMessage(color: Colors.green, message: 'Category saved successfully'),
    );

    // ✅ Return to dropdown with the created/updated category
    Navigator.pop(context, resultCategory);

    // ✅ Optional: show ad after returning
    if (widget.showAds == true) {
      final random = Random();
      // ~33% chance to show ad
      if (random.nextInt(3) == 0) {
        Future.delayed(const Duration(seconds: 1), () {
          AdService.showInterstitialAd();
        });
      }
    }

    setState(() => _isSubmitting = false);
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
