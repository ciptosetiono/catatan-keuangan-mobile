import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_note/models/currency_setting_model.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final CurrencySetting _setting;

  CurrencyInputFormatter({required CurrencySetting setting})
    : _setting = setting;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final showDecimal = _setting.showDecimal ?? true;
    final showSymbol = _setting.showSymbol ?? true;

    // Keep only digits
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    double value = double.tryParse(digitsOnly) ?? 0;
    if (showDecimal) value /= 100;

    final formatter = NumberFormat.currency(
      locale: _setting.locale,
      symbol: showSymbol ? '${_setting.symbol} ' : '',
      decimalDigits: showDecimal ? 2 : 0,
    );

    final newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
