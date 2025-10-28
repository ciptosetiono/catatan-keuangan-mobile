// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class MonthPicker extends StatelessWidget {
  final DateTime selectedMonth;
  final String? labelText;
  final void Function(DateTime) onMonthPicked;

  const MonthPicker({
    super.key,
    required this.selectedMonth,
    this.labelText,
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
                dialogTheme: const DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                colorScheme: const ColorScheme.light(
                  primary: Colors.blueAccent,
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: ButtonStyle(
                    textStyle: MaterialStateProperty.all(
                      const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              child: Builder(
                builder: (context) {
                  // cari tombol OK dan Cancel di dalam dialog
                  return Theme(
                    data: Theme.of(context).copyWith(
                      textButtonTheme: TextButtonThemeData(
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.resolveWith<
                            Color
                          >((states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey;
                            }
                            // Cancel button akan diwarnai abu-abu, OK tombol biru
                            return states.contains(MaterialState.focused)
                                ? Colors.blueAccent
                                : Colors.blueAccent;
                          }),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              ),
            );
          },
        );

        if (picked != null) onMonthPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText ?? '',
          labelStyle: const TextStyle(fontSize: 14, color: Colors.black87),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            // borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          prefixIcon: const Icon(
            Icons.calendar_month,
            color: Color.fromARGB(255, 112, 112, 112),
          ),
        ),
        isEmpty: false,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            formatted,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
