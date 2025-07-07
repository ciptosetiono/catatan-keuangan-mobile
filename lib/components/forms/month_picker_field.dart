import 'package:flutter/foundation.dart' show kIsWeb;
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
    if (kIsWeb) {
      // 🔽 Web version with dropdowns
      final currentYear = DateTime.now().year;
      final selectedYear = selectedMonth.year;
      final selectedMonthNumber = selectedMonth.month;

      return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedMonthNumber,
              decoration: const InputDecoration(
                labelText: "Bulan",
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (i) {
                final monthName = DateFormat.MMMM(
                  'id_ID',
                ).format(DateTime(0, i + 1));
                return DropdownMenuItem(value: i + 1, child: Text(monthName));
              }),
              onChanged: (month) {
                if (month != null) {
                  onMonthPicked(DateTime(selectedYear, month));
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: const InputDecoration(
                labelText: "Tahun",
                border: OutlineInputBorder(),
              ),
              items: List.generate(21, (i) {
                final year = currentYear - 10 + i;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (year) {
                if (year != null) {
                  onMonthPicked(DateTime(year, selectedMonthNumber));
                }
              },
            ),
          ),
        ],
      );
    } else {
      // 📱 Mobile version with MonthYearPicker dialog
      final formatted = DateFormat.yMMMM('id_ID').format(selectedMonth);

      return InkWell(
        onTap: () async {
          final picked = await showMonthYearPicker(
            context: context,
            initialDate: selectedMonth,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            locale: const Locale("id", "ID"),
          );
          if (picked != null) {
            onMonthPicked(picked);
          }
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Bulan',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
          ),
          child: Text(formatted),
        ),
      );
    }
  }
}
