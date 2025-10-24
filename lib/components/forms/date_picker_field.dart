import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDatePicked;
  final String label;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDatePicked,
    this.label = 'Select Date',
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Choose Date',
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Theme(
          data: theme.copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            colorScheme:
                isDark
                    ? const ColorScheme.dark(
                      primary: Colors.blueAccent,
                      onPrimary: Colors.white,
                      surface: Color(0xFF121212),
                      onSurface: Colors.white,
                    )
                    : const ColorScheme.light(
                      primary: Colors.blueAccent,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDatePicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48, // keep same height as WalletDropdown
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.grey, size: 22),
                const SizedBox(width: 12),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
