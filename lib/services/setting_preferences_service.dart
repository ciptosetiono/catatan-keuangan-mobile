import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_note/models/currency_setting_model.dart';

class SettingPreferencesService {
  static const String _defaultWalletKey = 'default_wallet_id';
  static const String _defaultIncomeCategoryKey = 'default_income_category_id';
  static const String _defaultExpenseCategoryKey =
      'default_expense_category_id';

  // New keys for currency
  static const String _currencyCodeKey = 'currency_code';
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _currencyLocaleKey = 'currency_locale';
  static const _showSymbolKey = 'currency_show_symbol';
  static const _showDecimalKey = 'currency_show_decimal';

  // Save default wallet
  Future<void> setDefaultWallet(String walletId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultWalletKey, walletId);
  }

  // Get default wallet
  Future<String?> getDefaultWallet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultWalletKey);
  }

  // Save default category (optional for later)
  Future<void> setDefaultCategory({
    required String categoryId,
    String? type = 'income',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (type == 'income') {
      await prefs.setString(_defaultIncomeCategoryKey, categoryId);
    } else {
      await prefs.setString(_defaultExpenseCategoryKey, categoryId);
    }
  }

  // Get default category
  Future<String?> getDefaultCategory({String? type = 'income'}) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == 'income') {
      return prefs.getString(_defaultIncomeCategoryKey);
    } else {
      return prefs.getString(_defaultExpenseCategoryKey);
    }
  }

  // =========================
  // Currency Setting
  // =========================

  Future<void> setCurrencySetting(CurrencySetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, setting.currencyCode);
    await prefs.setString(_currencySymbolKey, setting.symbol);
    await prefs.setString(_currencyLocaleKey, setting.locale);
    await prefs.setBool(_showSymbolKey, setting.showSymbol ?? true);
    await prefs.setBool(_showDecimalKey, setting.showDecimal ?? true);
  }

  Future<CurrencySetting> getCurrencySetting() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_currencyCodeKey) ?? 'USD';
    final symbol = prefs.getString(_currencySymbolKey) ?? '\$';
    final locale = prefs.getString(_currencyLocaleKey) ?? 'en_US';
    final showSymbol = prefs.getBool(_showSymbolKey) ?? true;
    final showDecimal = prefs.getBool(_showDecimalKey) ?? true;

    return CurrencySetting(
      currencyCode: code,
      symbol: symbol,
      locale: locale,
      showSymbol: showSymbol,
      showDecimal: showDecimal,
    );
  }
}
