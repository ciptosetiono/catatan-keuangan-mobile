import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Ambil hanya digit
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Kalau kosong, kembalikan string kosong dengan cursor di awal
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse angka
    final number = int.parse(digitsOnly);

    // Format ulang
    final newText = _formatter.format(number);

    // Hitung perbedaan panjang teks sebelum dan sesudah
    final diff = newText.length - oldValue.text.length;

    // Tentukan posisi caret baru
    var newSelectionIndex = newValue.selection.end + diff;

    // Clamp agar tidak melebihi panjang teks
    if (newSelectionIndex > newText.length) {
      newSelectionIndex = newText.length;
    } else if (newSelectionIndex < 0) {
      newSelectionIndex = 0;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}
