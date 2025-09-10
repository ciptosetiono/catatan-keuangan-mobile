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
      onTap: () async {
        final picked = await showMonthYearPicker(
          context: context,
          initialDate: selectedMonth,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.blue, // warna utama
                  onPrimary: Colors.white, // teks tombol OK
                  onSurface: Colors.black, // teks default
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
        decoration: const InputDecoration(
          labelText: 'Month',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(formatted),
      ),
    );
  }
}
