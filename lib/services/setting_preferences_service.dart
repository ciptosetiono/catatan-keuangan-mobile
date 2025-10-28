import 'package:shared_preferences/shared_preferences.dart';

class SettingPreferencesService {
  static const String _defaultWalletKey = 'default_wallet_id';
  static const String _defaultIncomeCategoryKey = 'default_income_category_id';
  static const String _defaultExpenseCategoryKey =
      'default_expense_category_id';

  Future<void> setOnboardingSeen() async {}

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
}
