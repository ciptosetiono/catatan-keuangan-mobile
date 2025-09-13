import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:money_note/constants/date_filter_option.dart';

class DateFilterDropdown extends StatelessWidget {
  final DateFilterOption selected;
  final void Function(
    DateFilterOption option, {
    DateTime? from,
    DateTime? to,
    String? label,
  })
  onFilterApplied;

  const DateFilterDropdown({
    super.key,
    required this.selected,
    required this.onFilterApplied,
  });

  Future<void> _handleChange(
    BuildContext context,
    DateFilterOption option,
  ) async {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    String label = '';

    switch (option) {
      case DateFilterOption.today:
        from = DateTime(now.year, now.month, now.day);
        to = from.add(const Duration(days: 1));
        label = 'Today';
        break;
      case DateFilterOption.thisMonth:
        from = DateTime(now.year, now.month);
        to = DateTime(now.year, now.month + 1);
        label = 'This Month';
        break;
      case DateFilterOption.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        from = DateTime(lastMonth.year, lastMonth.month);
        to = DateTime(now.year, now.month);
        label = 'Last Month';
        break;
      case DateFilterOption.last30Days:
        from = now.subtract(const Duration(days: 30));
        to = now.add(const Duration(days: 1));
        label = 'Last 30 Days';
        break;
      case DateFilterOption.thisYear:
        from = DateTime(now.year);
        to = DateTime(now.year + 1);
        label = 'This Year';
        break;
      case DateFilterOption.all:
        from = null;
        to = null;
        label = 'All Time';
        break;
      case DateFilterOption.custom:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now.add(const Duration(days: 365)),
          helpText: 'Select Date Range',
          cancelText: 'Cancel',
          confirmText: 'Apply',
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                dialogBackgroundColor: Colors.grey[50],
                colorScheme: const ColorScheme.light(
                  primary: Colors.blueAccent,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textTheme: Theme.of(context).textTheme.copyWith(
                  titleLarge: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  bodyMedium: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          from = picked.start;
          to = picked.end.add(const Duration(days: 1));
          label =
              '${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM yyyy').format(picked.end)}';
        } else {
          return;
        }
        break;
    }

    onFilterApplied(option, from: from, to: to, label: label);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              child: DropdownButton<DateFilterOption>(
                value: selected,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color.fromARGB(255, 15, 15, 15)),
                icon: const SizedBox.shrink(),
                items:
                    DateFilterOption.values.map((e) {
                      String text;
                      switch (e) {
                        case DateFilterOption.today:
                          text = 'Today';
                          break;
                        case DateFilterOption.thisMonth:
                          text = 'This Month';
                          break;
                        case DateFilterOption.lastMonth:
                          text = 'Last Month';
                          break;
                        case DateFilterOption.last30Days:
                          text = 'Last 30 Days';
                          break;
                        case DateFilterOption.thisYear:
                          text = 'This Year';
                          break;
                        case DateFilterOption.all:
                          text = 'All Time';
                          break;
                        case DateFilterOption.custom:
                          text = 'Custom...';
                          break;
                      }
                      return DropdownMenuItem(value: e, child: Text(text));
                    }).toList(),
                onChanged: (option) {
                  if (option != null) _handleChange(context, option);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.date_range, color: Colors.black),
        ],
      ),
    );
  }
}

/// --- Custom Localizations to override Save -> Apply ---
class _CustomMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CustomMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final defaultLocalization = await GlobalMaterialLocalizations.delegate.load(
      locale,
    );
    return _CustomMaterialLocalizations(defaultLocalization);
  }

  @override
  bool shouldReload(_CustomMaterialLocalizationsDelegate old) => false;
}

class _CustomMaterialLocalizations extends DefaultMaterialLocalizations {
  final MaterialLocalizations _default;
  _CustomMaterialLocalizations(this._default);

  @override
  String get saveButtonLabel => 'Apply';
}
