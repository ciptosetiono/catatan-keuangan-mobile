import 'package:intl/intl.dart';
import '../models/currency_setting_model.dart';
import '../services/setting_preferences_service.dart';

class CurrencyFormatter {
  final SettingPreferencesService _preferencesService =
      SettingPreferencesService();

  /// Decode currency string (e.g. "Rp 12.000" or "$1,200.50") into a numeric value
  double decodeAmount(String input) {
    final rawAmount = input.replaceAll(RegExp(r'[^\d.,-]'), '').trim();

    // Normalize decimal separator
    String normalized = rawAmount;
    if (rawAmount.contains(',') && rawAmount.contains('.')) {
      int lastComma = rawAmount.lastIndexOf(',');
      int lastDot = rawAmount.lastIndexOf('.');
      if (lastComma > lastDot) {
        normalized = rawAmount.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = rawAmount.replaceAll(',', '');
      }
    } else if (rawAmount.contains(',')) {
      if (rawAmount.indexOf(',') == rawAmount.length - 3) {
        normalized = rawAmount.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = rawAmount.replaceAll(',', '');
      }
    } else if (rawAmount.contains('.')) {
      if (rawAmount.indexOf('.') == rawAmount.length - 3) {
        normalized = rawAmount.replaceAll(',', '');
      } else {
        normalized = rawAmount.replaceAll('.', '');
      }
    }

    return double.tryParse(normalized) ?? 0;
  }

  /// Encode numeric value into localized currency string (e.g. Rp 12.000)
  Future<String> encode(num amount) async {
    final CurrencySetting setting =
        await _preferencesService.getCurrencySetting();

    final bool showDecimal = setting.showDecimal ?? true;
    final bool showSymbol = setting.showSymbol ?? true;

    final formatCurrency = NumberFormat.currency(
      locale: setting.locale,
      symbol: showSymbol ? '${setting.symbol} ' : '',
      decimalDigits: showDecimal ? 2 : 0,
    );

    return formatCurrency.format(amount);
  }

  /// Sync helper — returns formatted string without waiting (default locale)
  String quickEncode(num amount, {CurrencySetting? setting}) {
    final s =
        setting ??
        CurrencySetting(currencyCode: 'IDR', symbol: 'Rp', locale: 'id_ID');

    final formatCurrency = NumberFormat.currency(
      locale: s.locale,
      symbol: (s.showSymbol ?? true) ? '${s.symbol} ' : '',
      decimalDigits: (s.showDecimal ?? false) ? 2 : 0,
    );

    return formatCurrency.format(amount);
  }
}
