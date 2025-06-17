import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final List<String> incomeCategories = ['Gaji', 'Bonus'];
  final List<String> expenseCategories = ['Makan', 'Transportasi'];

  final TextEditingController _controller = TextEditingController();
  String _type = 'income';

  void _showAddCategoryDialog() {
    _controller.clear();
    _type = 'income';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  DropdownMenuItem(
                    value: 'expense',
                    child: Text('Pengeluaran'),
                  ),
                ],
                onChanged: (val) => setState(() => _type = val ?? 'income'),
              ),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Nama Kategori'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controller.clear();
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = _controller.text.trim();
                if (value.isNotEmpty) {
                  setState(() {
                    if (_type == 'income') {
                      incomeCategories.add(value);
                    } else {
                      expenseCategories.add(value);
                    }
                  });
                }
                _controller.clear();
                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(String oldValue, String type) {
    _controller.text = oldValue;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Kategori'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Nama Baru'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controller.clear();
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = _controller.text.trim();
                if (newValue.isNotEmpty) {
                  setState(() {
                    if (type == 'income') {
                      final index = incomeCategories.indexOf(oldValue);
                      if (index != -1) incomeCategories[index] = newValue;
                    } else {
                      final index = expenseCategories.indexOf(oldValue);
                      if (index != -1) expenseCategories[index] = newValue;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Kategori "$oldValue" diubah menjadi "$newValue"',
                      ),
                    ),
                  );
                }
                _controller.clear();
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryList(String title, List<String> items, Color color) {
    final type = title == 'Pemasukan' ? 'income' : 'expense';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (e) => Card(
            child: ListTile(
              leading: Icon(Icons.label, color: color),
              title: Text(e),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () => _showEditCategoryDialog(e, type),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildCategoryList('Pemasukan', incomeCategories, Colors.green),
            _buildCategoryList('Pengeluaran', expenseCategories, Colors.red),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
