import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:ttsapp/screens/settings_screen.dart';

import '../services/document_reader_service.dart';
import '../services/text_to_speech_service.dart';
import 'saved_files_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DocumentReaderService _documentReaderService = DocumentReaderService();
  final TextToSpeechService _textToSpeechService = TextToSpeechService();

  String _extractedText = "";
  int _currentWordIndex = -1;

  double _pitch = 1.0;
  double _speechRate = 0.6;

  @override
  void initState() {
    super.initState();
    _textToSpeechService.setWordChangeCallback((index) {
      setState(() => _currentWordIndex = index);
    });
  }

  Future<void> _pickAndReadDocument() async {
    String? text = await _documentReaderService.pickAndReadDocument();
    setState(() {
      _extractedText = text ?? "No text extracted.";
      _currentWordIndex = -1;
    });
  }

  Future<void> _speakText() async {
    if (_extractedText.isNotEmpty) {
      await _textToSpeechService.updatePitch(_pitch);
      await _textToSpeechService.updateSpeechRate(_speechRate);
      await _textToSpeechService.speak(_extractedText);
    } else {
      _showSnackBar("No text to speak.");
    }
  }

  Future<void> _pauseSpeech() async {
    await _textToSpeechService.pause();
    setState(() {});
  }

  Future<void> _resumeSpeech() async {
    await _textToSpeechService.resume();
    setState(() {});
  }

  Future<void> _stopSpeech() async {
    await _textToSpeechService.stop();
    setState(() {});
  }

  Future<void> _startNewDocument() async {
    await _textToSpeechService.stop();
    setState(() {
      _extractedText = "";
      _currentWordIndex = -1;
    });
    await _pickAndReadDocument();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openSaveOptions() async {
    if (_extractedText.isEmpty) {
      _showSnackBar("No text available to read aloud.");
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        String fileName = "audio_file";
        String format = "wav";
        return StatefulBuilder(
          builder: (context, bottomSheetSetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Save Audio Options",
                      style: Theme.of(context).textTheme.titleMedium),
                  TextField(
                    onChanged: (value) =>
                        bottomSheetSetState(() => fileName = value.trim()),
                    decoration: const InputDecoration(
                      labelText: "File Name",
                      hintText: "Enter file name",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("Choose Format: "),
                      DropdownButton<String>(
                        value: format,
                        onChanged: (val) =>
                            bottomSheetSetState(() => format = val!),
                        items: const [
                          DropdownMenuItem(value: "wav", child: Text("WAV")),
                          DropdownMenuItem(value: "mp3", child: Text("MP3")),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (fileName.isEmpty) return;
                      await _readAloudAndSave(fileName, format);
                    },
                    child: const Text("Save & Speak"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _readAloudAndSave(String fileName, String format) async {
    await _textToSpeechService.updatePitch(_pitch);
    await _textToSpeechService.updateSpeechRate(_speechRate);
    await _textToSpeechService.stop();

    final savedPath = await _textToSpeechService.synthesizeAndRelocate(
      _extractedText,
      fileName,
      format: format,
    );

    await _textToSpeechService.speak(_extractedText);

    if (savedPath != null) {
      _showSnackBar("Audio saved at $savedPath");
      _showOptionToShare(savedPath);
    } else {
      _showSnackBar("Failed to save audio file.");
    }
  }

  void _showOptionToShare(String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Audio Saved!"),
        content: const Text("Would you like to share the audio file now?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(filePath)],
                  text: "Check out my TTS audio file!");
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textToSpeechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = _extractedText.split(RegExp(r'\s+'));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Reader & TTS"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "New Document",
            onPressed: _startNewDocument,
          )
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.grey[850]!, Colors.grey[800]!]
                            : [Colors.blue, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book,
                            size: 28, color: theme.colorScheme.onPrimary),
                        const SizedBox(width: 12),
                        Text(
                          "TTS App Menu",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.folder_outlined,
                        color: theme.colorScheme.onSurface),
                    title: Text("Saved Files",
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SavedFilesScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings,
                        color: theme.colorScheme.onSurface),
                    title: Text("Settings",
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  const Divider(),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(10),
              elevation: 2,
              child: ListTile(
                title: const Text("Pick Document",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Tap to select PDF or DOCX"),
                trailing: const Icon(Icons.file_open),
                onTap: _pickAndReadDocument,
              ),
            ),
            if (_extractedText.isNotEmpty)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text("TTS Settings",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Text("Pitch"),
                          Expanded(
                            child: Slider(
                              value: _pitch,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              label: _pitch.toStringAsFixed(2),
                              onChanged: (val) => setState(() => _pitch = val),
                              onChangeEnd: (val) =>
                                  _textToSpeechService.updatePitchOnTheFly(val),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Rate"),
                          Expanded(
                            child: Slider(
                              value: _speechRate,
                              min: 0.2,
                              max: 1.0,
                              divisions: 8,
                              label: _speechRate.toStringAsFixed(2),
                              onChanged: (val) =>
                                  setState(() => _speechRate = val),
                              onChangeEnd: (val) =>
                                  _textToSpeechService.updateRateOnTheFly(val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _extractedText.isEmpty
                    ? const Center(child: Text("No text extracted yet."))
                    : SingleChildScrollView(
                        child: RichText(
                          text: TextSpan(
                            children: words.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final word = entry.value;
                              return TextSpan(
                                text: "$word ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: idx == _currentWordIndex
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: idx == _currentWordIndex
                                      ? Colors.blue
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color, // ✅ auto adapt
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
            if (_extractedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: _speakText,
                      tooltip: "Play",
                    ),
                    IconButton(
                      icon: const Icon(Icons.pause),
                      onPressed:
                          _textToSpeechService.ttsState == TtsState.playing
                              ? _pauseSpeech
                              : null,
                      tooltip: "Pause",
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill),
                      onPressed:
                          _textToSpeechService.ttsState == TtsState.paused
                              ? _resumeSpeech
                              : null,
                      tooltip: "Resume",
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed:
                          _textToSpeechService.ttsState != TtsState.stopped
                              ? _stopSpeech
                              : null,
                      tooltip: "Stop",
                    ),
                    ElevatedButton.icon(
                      onPressed: _openSaveOptions,
                      icon: const Icon(Icons.save),
                      label: const Text("Save & Speak"),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
