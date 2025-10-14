import 'package:flutter/foundation.dart';

class AdConfig {
  /// --- REAL (PRODUCTION) APP IDs ---
  static const _appIdAndroidProd = 'ca-app-pub-2030215353517275~2439373453';

  /// --- REAL (PRODUCTION) UNIT IDs ---
  static const _bannerAdAndroidProd = 'ca-app-pub-2030215353517275/1930207181';
  static const _interstitialAdAndroidProd =
      'ca-app-pub-2030215353517275/4034616020';

  /// --- TEST APP IDs (Google Sample) ---
  static const _appIdAndroidTest = 'ca-app-pub-3940256099942544~3347511713';

  /// --- TEST UNIT IDs (Google Sample) ---
  static const _bannerAdAndroidTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _interstitialAdAndroidTest =
      'ca-app-pub-3940256099942544/1033173712';

  /// --- GETTERS: otomatis pilih berdasarkan mode & platform ---
  static String get appId {
    return kReleaseMode ? _appIdAndroidProd : _appIdAndroidTest;
  }

  static String get bannerAdUnitId {
    return kReleaseMode ? _bannerAdAndroidProd : _bannerAdAndroidTest;
  }

  static String get interstitialAdUnitId {
    return kReleaseMode
        ? _interstitialAdAndroidProd
        : _interstitialAdAndroidTest;
  }
}
