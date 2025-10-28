import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_note/models/currency_setting_model.dart';
import 'package:money_note/services/setting_preferences_service.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  CurrencySetting? _cachedSetting;
  final SettingPreferencesService _prefsService = SettingPreferencesService();

  CurrencyInputFormatter() {
    _loadCurrencySetting();
  }

  Future<void> _loadCurrencySetting() async {
    _cachedSetting = await _prefsService.getCurrencySetting();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final setting =
        _cachedSetting ??
        CurrencySetting(currencyCode: 'USD', symbol: '\$', locale: 'en_US');

    final showDecimal = setting.showDecimal ?? true;
    final showSymbol = setting.showSymbol ?? true;

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Handle decimal places (divide by 100 if decimals shown)
    double value = double.tryParse(digitsOnly) ?? 0;
    if (showDecimal) {
      value = value / 100;
    }

    // Build formatter based on user setting
    final formatter = NumberFormat.currency(
      locale: setting.locale,
      symbol: showSymbol ? '${setting.symbol} ' : '',
      decimalDigits: showDecimal ? 2 : 0,
    );

    final newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
