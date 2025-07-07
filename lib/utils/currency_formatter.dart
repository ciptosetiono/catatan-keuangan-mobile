import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Helper function to parse currency string to double
  double decodeAmount(String input) {
    final rawAmount = input.replaceAll(RegExp(r'[^\d.,-]'), '').trim();

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

  String encode(num amount) {
    final NumberFormat formatCurrency = NumberFormat.currency(
      decimalDigits: 0,
      symbol: '',
    );
    return formatCurrency.format(amount);
  }
}
