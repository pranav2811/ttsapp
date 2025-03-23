import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentReaderService {
  Future<String?> pickAndReadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String filePath = file.path;

      if (filePath.endsWith('.pdf')) {
        return await _readPdf(file);
      } else if (filePath.endsWith('.docx')) {
        return await _readDocx(file);
      }
    }
    return null;
  }

  Future<String> _readPdf(File file) async {
    try {
      List<int> bytes = await file.readAsBytes();
      PdfDocument document = PdfDocument(inputBytes: bytes);
      return PdfTextExtractor(document).extractText();
    } catch (e) {
      return "Error reading PDF file: $e";
    }
  }

  Future<String> _readDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive.files) {
        if (file.name == 'word/document.xml') {
          final content = utf8.decode(file.content as List<int>);
          return _extractTextFromXml(content);
        }
      }

      return "Error: document.xml not found in DOCX file.";
    } catch (e) {
      return "Error reading DOCX file: $e";
    }
  }

  String _extractTextFromXml(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final textNodes = document.findAllElements('w:t');
    return textNodes.map((node) => node.text).join(' ');
  }
}
