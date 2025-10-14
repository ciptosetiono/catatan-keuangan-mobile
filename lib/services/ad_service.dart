import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../config/ad_config.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;

  static final String _interstitialUnitId = AdConfig.interstitialAdUnitId;

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) print('Interstitial failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd(); // pre-load next one
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      _isAdLoaded = false;
    } else {
      loadInterstitialAd();
    }
  }
}
