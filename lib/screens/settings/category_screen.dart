import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  String _searchQuery = '';
  String _filterType = 'all';

  void _openCategoryForm({Category? category}) {
    final TextEditingController _controller = TextEditingController(
      text: category?.name ?? '',
    );
    String selectedType = category?.type ?? 'expense';
    final isEdit = category != null;

    showDialog(
      context: context,
      builder: (context) {
        String tempSelectedType = selectedType;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(isEdit ? 'Edit Category' : 'Add Category'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'income',
                          groupValue: tempSelectedType,
                          title: const Text('Income'),
                          activeColor: Colors.lightBlue,
                          tileColor:
                              tempSelectedType == 'income'
                                  ? Colors.lightBlue
                                  : null,
                          onChanged: (value) {
                            setStateDialog(() => tempSelectedType = value!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'expense',
                          groupValue: tempSelectedType,
                          title: const Text('Expense'),
                          onChanged: (value) {
                            setStateDialog(() => tempSelectedType = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 65, 64, 64),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _controller.text.trim();
                if (name.isEmpty) return;

                final userId = FirebaseAuth.instance.currentUser!.uid;
                final newCategory = Category(
                  id: category?.id ?? '',
                  name: name,
                  type: tempSelectedType,
                  userId: userId,
                );

                if (isEdit) {
                  await _categoryService.updateCategory(newCategory);
                } else {
                  await _categoryService.addCategory(newCategory);
                }

                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Categori'),
            content: Text(
              'Are you sure to delete category "${category.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _categoryService.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged:
                                (value) => setState(() => _searchQuery = value),
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'search category...',
                              hintStyle: TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filterType,
                              isExpanded: true,
                              icon: const SizedBox.shrink(),
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black),
                              hint: const Text(
                                'Filter',
                                style: TextStyle(color: Colors.black),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All Types'),
                                ),
                                DropdownMenuItem(
                                  value: 'income',
                                  child: Text('Income'),
                                ),
                                DropdownMenuItem(
                                  value: 'expense',
                                  child: Text('Expense'),
                                ),
                              ],
                              onChanged:
                                  (val) => setState(() => _filterType = val!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.filter_alt, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Category>>(
              stream: _categoryService.getCategoryStream(
                query: _searchQuery,
                type: _filterType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data ?? [];
                if (categories.isEmpty) {
                  return const Center(
                    child: Text('There are no categories yet. Add one now!'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: categories.length,
                  itemBuilder: (ctx, i) {
                    final c = categories[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(c.name),
                        subtitle: Text(
                          c.type == 'income' ? 'Income' : 'Expense',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _openCategoryForm(category: c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _deleteCategory(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryForm(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
