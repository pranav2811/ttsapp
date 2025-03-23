import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;

enum TtsState { playing, paused, stopped }

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  late List<String> _words;
  late Function(int) _onWordChange;
  int _currentWordIndex = 0;

  TtsState _ttsState = TtsState.stopped;
  TtsState get ttsState => _ttsState;

  bool _shouldResume = false;

  TextToSpeechService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setEngine("com.google.android.tts");
    } catch (e) {
      print("Unable to set Google TTS engine: $e");
    }

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.awaitSynthCompletion(true);

    _flutterTts.setProgressHandler(
        (String text, int start, int end, String spokenWord) {
      final normalizedSpoken = _normalize(spokenWord);
      if (_currentWordIndex < _words.length) {
        final nextWord = _normalize(_words[_currentWordIndex]);
        if (normalizedSpoken == nextWord) {
          _onWordChange(_currentWordIndex);
          _currentWordIndex++;
        }
      }
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      _shouldResume = false;
      _onWordChange(-1);
      print("TTS playback completed.");
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
      _shouldResume = false;
      print("TTS engine error: $msg");
    });
  }

  String _normalize(String word) {
    return word.replaceAll(RegExp(r'[^\w\s]+'), '').toLowerCase();
  }

  void setWordChangeCallback(Function(int) callback) {
    _onWordChange = callback;
  }

  Future<void> updatePitch(double pitch) => _flutterTts.setPitch(pitch);
  Future<void> updateSpeechRate(double rate) => _flutterTts.setSpeechRate(rate);

  Future<void> speak(String text, {bool resumeMode = false}) async {
    if (text.isEmpty) return;

    if (!resumeMode) {
      _words = text.split(RegExp(r'\s+'));
      _currentWordIndex = 0;
    }

    _ttsState = TtsState.playing;
    _shouldResume = false;

    final textToSpeak = _remainingText();
    if (textToSpeak.isNotEmpty) {
      await _flutterTts.speak(textToSpeak);
    }
  }

  Future<void> pause() async {
    if (_ttsState == TtsState.playing) {
      _ttsState = TtsState.paused;
      _shouldResume = true;
      await _flutterTts.stop();
    }
  }

  Future<void> resume() async {
    if (_ttsState == TtsState.paused && _shouldResume) {
      await speak("", resumeMode: true);
    }
  }

  Future<void> stop() async {
    _shouldResume = false;
    _currentWordIndex = -1;
    _ttsState = TtsState.stopped;
    await _flutterTts.stop();
  }

  String _remainingText() {
    if (_currentWordIndex < 0 || _currentWordIndex >= _words.length) return "";
    return _words.sublist(_currentWordIndex).join(" ");
  }

  /// ✅ WORKAROUND: Synthesize to internal file, then locate it and copy/rename to Downloads folder.
  Future<String?> synthesizeAndRelocate(
    String text,
    String desiredFileName, {
    String format = "wav", // could be "mp3" or "wav"
  }) async {
    try {
      final tempFileName = "flutter_tts_temp.$format";
      final tempPath =
          "/data/user/0/com.example.ttsapp/code_cache/$tempFileName";

      final result = await _flutterTts.synthesizeToFile(text, tempPath);
      if (result != 1) {
        print("TTS engine failed to synthesize.");
        return null;
      }

      print("Waiting briefly to allow file to appear...");
      await Future.delayed(const Duration(seconds: 2));

      // Directory where Google TTS stores the actual output (system folder)
      final audioDir = Directory('/storage/emulated/0/Music');
      if (!audioDir.existsSync()) {
        print("Audio directory not found.");
        return null;
      }

      // Look for files matching the selected format (wav/mp3)
      final audioFiles = audioDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.$format'))
          .toList();

      if (audioFiles.isEmpty) {
        print("No .$format files found in Music directory.");
        return null;
      }

      // Sort by last modified time (most recent first)
      audioFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latestFile = audioFiles.first;

      print("Latest audio file found: ${latestFile.path}");

      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final newFilePath = p.join(downloadsDir.path, "$desiredFileName.$format");
      final copiedFile = await latestFile.copy(newFilePath);

      print("Copied to: ${copiedFile.path}");
      return copiedFile.path;
    } catch (e) {
      print("Error in synthesizeAndRelocate: $e");
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    _flutterTts.stop();
  }

  /// Real-time pitch change
  Future<void> updatePitchOnTheFly(double pitch) async {
    if (_ttsState == TtsState.playing) {
      final savedIndex = _currentWordIndex;
      final savedWords = _words;

      final oldCompletionHandler = _flutterTts.completionHandler;
      _flutterTts.setCompletionHandler(() {});

      await _flutterTts.stop();
      _ttsState = TtsState.paused;
      _shouldResume = true;

      _flutterTts.setCompletionHandler(oldCompletionHandler!);
      await _flutterTts.setPitch(pitch);

      _words = savedWords;
      _currentWordIndex = savedIndex;

      await speak("", resumeMode: true);
    } else {
      await _flutterTts.setPitch(pitch);
    }
  }

  /// Real-time speech rate change
  Future<void> updateRateOnTheFly(double rate) async {
    if (_ttsState == TtsState.playing) {
      final savedIndex = _currentWordIndex;
      final savedWords = _words;

      final oldCompletionHandler = _flutterTts.completionHandler;
      _flutterTts.setCompletionHandler(() {});

      await _flutterTts.stop();
      _ttsState = TtsState.paused;
      _shouldResume = true;

      _flutterTts.setCompletionHandler(oldCompletionHandler!);
      await _flutterTts.setSpeechRate(rate);

      _words = savedWords;
      _currentWordIndex = savedIndex;

      await speak("", resumeMode: true);
    } else {
      await _flutterTts.setSpeechRate(rate);
    }
  }
}
