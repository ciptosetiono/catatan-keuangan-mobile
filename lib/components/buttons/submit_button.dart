import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;
  final String label;

  const SubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16),
      ),
      child:
          isSubmitting
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : Text(label),
    );
  }
}
