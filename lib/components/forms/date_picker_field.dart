import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDatePicked;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDatePicked,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal',
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Theme(
          data: theme.copyWith(
            colorScheme:
                isDark
                    ? const ColorScheme.dark(
                      primary: Colors.lightBlue,
                      onPrimary: Colors.white,
                      surface: Color(0xFF121212),
                      onSurface: Colors.white,
                    )
                    : const ColorScheme.light(
                      primary: Colors.lightBlue,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
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
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedDate, style: theme.textTheme.bodyLarge),
            const Icon(Icons.calendar_month_outlined, size: 22),
          ],
        ),
      ),
    );
  }
}
