import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_note/constants/date_filter_option.dart';

class DateFilterDropdown extends StatefulWidget {
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

  @override
  State<DateFilterDropdown> createState() => _DateFilterDropdownState();
}

class _DateFilterDropdownState extends State<DateFilterDropdown> {
  String? _customLabel;

  Future<void> _handleChange(DateFilterOption option) async {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    String label = '';

    switch (option) {
      case DateFilterOption.today:
        from = DateTime(now.year, now.month, now.day);
        to = from.add(const Duration(days: 1));
        label = 'Today';
        _customLabel = null;
        break;
      case DateFilterOption.thisMonth:
        from = DateTime(now.year, now.month);
        to = DateTime(now.year, now.month + 1);
        label = 'This Month';
        _customLabel = null;
        break;
      case DateFilterOption.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        from = DateTime(lastMonth.year, lastMonth.month);
        to = DateTime(now.year, now.month);
        label = 'Last Month';
        _customLabel = null;
        break;
      case DateFilterOption.last30Days:
        from = now.subtract(const Duration(days: 30));
        to = now.add(const Duration(days: 1));
        label = 'Last 30 Days';
        _customLabel = null;
        break;
      case DateFilterOption.thisYear:
        from = DateTime(now.year);
        to = DateTime(now.year + 1);
        label = 'This Year';
        _customLabel = null;
        break;
      case DateFilterOption.all:
        from = null;
        to = null;
        label = 'All Time';
        _customLabel = null;
        break;
      case DateFilterOption.custom:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now.add(const Duration(days: 365)),
          helpText: 'Select Date Range',
          builder: (context, child) {
            return Localizations.override(
              context: context,
              delegates: [
                _CustomLocalizationsDelegate(), // 👈 our custom text override
                DefaultWidgetsLocalizations.delegate,
              ],
              locale: const Locale('en', 'US'),
              child: Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                child: child!,
              ),
            );
          },
        );

        if (picked != null) {
          from = picked.start;
          to = picked.end.add(const Duration(days: 1));
          _customLabel =
              '${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM yyyy').format(picked.end)}';
          label = _customLabel!;
        } else {
          return;
        }
        break;
    }

    setState(() {});
    widget.onFilterApplied(option, from: from, to: to, label: label);
  }

  String getLabel(DateFilterOption option) {
    if (option == DateFilterOption.custom && _customLabel != null) {
      return _customLabel!;
    }

    switch (option) {
      case DateFilterOption.today:
        return 'Today';
      case DateFilterOption.thisMonth:
        return 'This Month';
      case DateFilterOption.lastMonth:
        return 'Last Month';
      case DateFilterOption.last30Days:
        return 'Last 30 Days';
      case DateFilterOption.thisYear:
        return 'This Year';
      case DateFilterOption.all:
        return 'All Time';
      case DateFilterOption.custom:
        return 'Custom...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Color.fromARGB(255, 78, 78, 78)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateFilterOption>(
                value: widget.selected,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
                items:
                    DateFilterOption.values.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          getLabel(e),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (option) {
                  if (option != null) _handleChange(option);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomLocalizations extends DefaultMaterialLocalizations {
  @override
  String get okButtonLabel => 'Apply'; // ✅ replaces “Save”
  @override
  String get cancelButtonLabel => 'Cancel'; // ✅ consistent style
}

class _CustomLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CustomLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return SynchronousFuture<MaterialLocalizations>(_CustomLocalizations());
  }

  @override
  bool shouldReload(_CustomLocalizationsDelegate old) => false;
}
