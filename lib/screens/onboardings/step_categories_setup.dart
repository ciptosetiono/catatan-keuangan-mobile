// lib/screens/onboarding/step_category_setup.dart
import 'package:flutter/material.dart';
import 'package:money_note/models/category_model.dart';
import 'package:money_note/services/sqlite/category_service.dart';

class StepCategoriesSetup extends StatefulWidget {
  const StepCategoriesSetup({super.key});

  @override
  State<StepCategoriesSetup> createState() => _StepCategoriesSetupState();
}

class _StepCategoriesSetupState extends State<StepCategoriesSetup> {
  final TextEditingController _nameController = TextEditingController();
  final CategoryService _categoryService = CategoryService();
  Stream<List<Category>>? _categoriesStream;

  void _load() {
    _categoriesStream = _categoryService.getCategoryStream();
  }

  Future<void> _add() async {
    if (_nameController.text.isEmpty) return;
    await _categoryService.addCategory(
      Category(id: '', name: _nameController.text, type: 'expense'),
    );
    _nameController.clear();
    _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Add Your Categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g. Food, Salary, Bills',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _add,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Category>>(
              stream: _categoriesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final categories = snapshot.data!;
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    return ListTile(
                      leading: Icon(
                        c.type == 'income'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                      title: Text(c.name),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
