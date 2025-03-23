import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MaterialApp(
    title: 'TTS App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const HomeScreen(),
  ));
}
