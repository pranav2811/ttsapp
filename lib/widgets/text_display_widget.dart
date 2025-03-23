import 'package:flutter/material.dart';

class TextDisplayWidget extends StatelessWidget {
  final String text;

  const TextDisplayWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Text(
        text.isEmpty ? "No text extracted yet." : text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
