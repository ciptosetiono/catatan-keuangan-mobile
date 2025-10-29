import 'package:flutter/material.dart';
import '../../utils/currency_input_formatter.dart';
import '../../services/setting_preferences_service.dart';
import '../../models/currency_setting_model.dart';

class CurrencyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final String? Function(String?)? validator;

  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.validator,
  });

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  CurrencySetting? _currencySetting;

  @override
  void initState() {
    super.initState();
    _loadCurrencySetting();
  }

  /// Load saved currency setting asynchronously
  void _loadCurrencySetting() async {
    final setting = await SettingPreferencesService().getCurrencySetting();
    // ignore: unnecessary_null_comparison
    if (setting != null) {
      setState(() {
        _currencySetting = setting;
      });
    }
  }

  /// Provide default currency setting immediately
  CurrencySetting get _effectiveSetting =>
      _currencySetting ??
      CurrencySetting(
        currencyCode: 'USD',
        symbol: '\$',
        locale: 'en_US',
        showDecimal: true,
        showSymbol: true,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter(setting: _effectiveSetting)],
          decoration: InputDecoration(
            hintText: widget.placeholder ?? 'Enter amount',
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}
