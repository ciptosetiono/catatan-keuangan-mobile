import 'package:flutter/material.dart';

class FlashMessage extends SnackBar {
  final String message;
  final Color color;

  FlashMessage({super.key, required this.message, this.color = Colors.blueGrey})
    : super(content: Text(message), backgroundColor: color);

  // The build method is not needed because SnackBar already implements it.
}
