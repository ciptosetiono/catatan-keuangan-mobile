import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_initializer.dart';
import 'package:money_note/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final User? user = await authService.signInWithGoogle();

      if (user == null) {
        // User cancelled Google sign-in
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login cancelled')));
        return;
      }

      // Initialize user data
      await initializeUserData();

      if (!mounted) return;

      // Navigate to home after successful login
      Navigator.pushReplacementNamed(context, '/home');

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 7, 85, 230),
                  Color.fromARGB(255, 40, 174, 236),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 💳 Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedOpacity(
                opacity: _isLoading ? 0.4 : 1,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ App logo
                    Image.asset(
                      'assets/app_transparent_logo.png',
                      height: 180,
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                    // ✅ Headline
                    Text(
                      'Welcome to MoneyNote!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ Subtext
                    Text(
                      'Track income and expenses, plan your budget, and stay on top of your money.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 🔘 Google Sign-In Button
                    ElevatedButton.icon(
                      icon: Image.asset(
                        'assets/google_logo.png',
                        height: 24,
                        width: 24,
                      ),
                      label: const Text(
                        'Connect With Google',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 4,
                        shadowColor: Colors.black45,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _isLoading ? null : () => _signInWithGoogle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔄 Loading overlay
          if (_isLoading)
            Container(
              width: size.width,
              height: size.height,
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
