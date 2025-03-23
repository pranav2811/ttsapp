import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class SavedFilesScreen extends StatelessWidget {
  const SavedFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadsDir = Directory('/storage/emulated/0/Download');
    final files = downloadsDir
        .listSync()
        .whereType<File>()
        .where((file) =>
            file.path.toLowerCase().endsWith('.wav') ||
            file.path.toLowerCase().endsWith('.mp3'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return Scaffold(
      appBar: AppBar(title: const Text("Saved Audio Files")),
      body: files.isEmpty
          ? const Center(child: Text("No saved audio files found."))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final fileName = p.basename(file.path);
                final modified = file.lastModifiedSync();
                final formattedTime =
                    DateFormat('yyyy-MM-dd HH:mm').format(modified);

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.audiotrack),
                    title: Text(fileName),
                    subtitle: Text("Modified: $formattedTime"),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            OpenFile.open(file.path);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            Share.shareXFiles([XFile(file.path)],
                                text: "Check out this audio file!");
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
