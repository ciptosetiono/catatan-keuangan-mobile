import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class MonthPickerField extends StatelessWidget {
  final DateTime selectedMonth;
  final void Function(DateTime) onMonthPicked;

  const MonthPickerField({
    super.key,
    required this.selectedMonth,
    required this.onMonthPicked,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat.yMMMM('en_US').format(selectedMonth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showMonthYearPicker(
          context: context,
          initialDate: selectedMonth,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                dialogTheme: DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                colorScheme: const ColorScheme.light(
                  primary: Colors.blueAccent, // highlight utama
                  onPrimary: Colors.white, // teks di atas primary
                  onSurface: Colors.black87, // teks default
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onMonthPicked(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Month',
          labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          suffixIcon: const Icon(
            Icons.calendar_month,
            color: Colors.blueAccent,
          ),
        ),
        child: Text(
          formatted,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
