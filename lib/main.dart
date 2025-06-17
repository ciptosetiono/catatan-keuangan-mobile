// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/home_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/report_screen.dart';
import 'screens/setting_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return MaterialApp(
          title: 'Personal Finance App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.lightBlue,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.lightBlue, // 👈 Global AppBar color
              foregroundColor: Colors.white, // 👈 Icon & text color
              elevation: 0,
            ),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Roboto',
            visualDensity: VisualDensity.adaptivePlatformDensity,
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
    PlannerScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Transaksi'),
    BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Planner'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
