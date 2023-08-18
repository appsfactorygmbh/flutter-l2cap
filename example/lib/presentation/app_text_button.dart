import 'package:flutter/material.dart';

class AppTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  const AppTextButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.blue),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(child: Text(text, style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }
}
