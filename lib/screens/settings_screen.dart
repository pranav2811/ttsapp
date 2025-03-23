import 'package:flutter/material.dart';
import '../main.dart'; // to access themeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _defaultPitch = 1.0;
  double _defaultRate = 0.6;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("TTS Defaults",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Default Pitch: ${_defaultPitch.toStringAsFixed(2)}"),
          Slider(
            value: _defaultPitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (val) => setState(() => _defaultPitch = val),
          ),
          const SizedBox(height: 10),
          Text("Default Rate: ${_defaultRate.toStringAsFixed(2)}"),
          Slider(
            value: _defaultRate,
            min: 0.2,
            max: 1.0,
            divisions: 8,
            onChanged: (val) => setState(() => _defaultRate = val),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: isDarkMode,
            onChanged: (enabled) {
              setState(() {
                themeNotifier.value =
                    enabled ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text("Clear Recent Files"),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Recent files cleared.")),
              );
            },
          ),
          const SizedBox(height: 30),
          const Divider(),
          const Text("About",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("TTS App v1.0.0\n© 2025 Prnav&Raj"),
        ],
      ),
    );
  }
}
