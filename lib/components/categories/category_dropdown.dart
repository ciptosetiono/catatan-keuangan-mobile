// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:money_note/models/category_model.dart';
import 'package:money_note/services/sqlite/category_service.dart';
import 'package:money_note/screens/categories/category_form_screen.dart';

class CategoryDropdown extends StatefulWidget {
  final String? type;
  final String? value;
  final void Function(String?) onChanged;
  final String label;

  const CategoryDropdown({
    super.key,
    this.type,
    required this.value,
    required this.onChanged,
    this.label = 'Select Category',
  });

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  String? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant CategoryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _currentValue) {
      setState(() => _currentValue = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Category>>(
      stream: CategoryService().getCategoryStream(type: widget.type),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];

        if (_currentValue != null &&
            !categories.any((c) => c.id == _currentValue)) {
          _currentValue = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Expanded dropdown
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentValue,
                        isExpanded: true,
                        hint: Text(
                          'Select Category',
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        items:
                            categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.name),
                              );
                            }).toList(),
                        onChanged: (val) {
                          setState(() => _currentValue = val);
                          widget.onChanged(val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Add button
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => CategoryFormScreen(
                                defaultType: widget.type,
                                showAds: false,
                              ),
                        ),
                      );

                      if (result is Category) {
                        setState(() => _currentValue = result.id);
                        widget.onChanged(result.id);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
