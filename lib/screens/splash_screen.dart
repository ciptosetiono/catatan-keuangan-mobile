import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/firebase_options.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late AnimationController _textController;
  late Animation<Offset> _textAnimation;

  double progress = 0.0;

  //InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();

    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo bounce animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();

    // Text slide animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Run Firebase & DateFormatting in parallel
      List<Future<void>> tasks = [_initFirebase(), _initializeDateFormatting()];

      for (int i = 0; i < tasks.length; i++) {
        await tasks[i];
        setState(() {
          progress = (i + 1) / (tasks.length + 1); // +1 for Ads
        });
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Initialize Google Mobile Ads
      // await MobileAds.instance.initialize();

      // Update progress
      setState(() {
        progress = 1.0;
      });

      // Preload Interstitial Ad
      _preloadInterstitialAd();

      // Navigate to main screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      // Optionally, navigate anyway or show error
    }
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _initializeDateFormatting() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale.toString();
    await initializeDateFormatting(locale, null);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _preloadInterstitialAd() {
    /*
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print("Interstitial preloaded");
        },
        onAdFailedToLoad: (error) {
          print("Failed to preload interstitial: $error");
        },
      ),
    );
    */
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    //_interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoAnimation,
                child: Image.asset(
                  'assets/app_transparent_logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 20),
              SlideTransition(
                position: _textAnimation,
                child: const Text(
                  "Moneyger",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
