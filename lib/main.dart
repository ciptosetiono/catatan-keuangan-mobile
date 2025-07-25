// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/transactions/transaction_screen.dart';
import 'screens/budgets/budget_screen.dart';
import 'screens/wallets/wallet_screen.dart';
import 'screens/settings/setting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeDateFormatting();
  await _initializeFirebase();
  runApp(const MyApp());
}

Future<void> _initializeDateFormatting() async {
  final locale = WidgetsBinding.instance.platformDispatcher.locale.toString();
  await initializeDateFormatting(locale, null);
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return MaterialApp(
          title: 'My Money Note',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightBlue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
              centerTitle: false,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              labelLarge: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F6FA),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          home:
              snapshot.connectionState == ConnectionState.waiting
                  ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                  : snapshot.hasData
                  ? const MainPage()
                  : const LoginScreen(),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionScreen(),
    BudgetScreen(),
    WalletScreen(),
    SettingScreen(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.swap_horiz_outlined),
      activeIcon: Icon(Icons.swap_horiz),
      label: 'Transactions',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.pie_chart_outline),
      activeIcon: Icon(Icons.pie_chart),
      label: 'Budgets',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.wallet_outlined),
      activeIcon: Icon(Icons.wallet),
      label: 'Wallets',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.more_horiz_outlined),
      activeIcon: Icon(Icons.more_horiz),
      label: 'Other',
    ),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: _items,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 10,
      ),
    );
  }
}
