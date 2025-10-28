// lib/screens/onboarding/step_done.dart
import 'package:flutter/material.dart';

class StepDone extends StatelessWidget {
  const StepDone({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            Text('All Set!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
              'You’ve set up your wallets and categories.\nLet’s start tracking your money!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
