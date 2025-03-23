import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode mode, __) {
        return MaterialApp(
          title: 'TTS App',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              secondary: Colors.teal,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
