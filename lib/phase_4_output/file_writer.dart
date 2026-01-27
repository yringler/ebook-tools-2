import 'dart:convert';
import 'dart:io';
import 'package:html/dom.dart';
import '../phase_1_navigation/file_system.dart';

/// Writes processed HTML files to disk.
/// Ensures proper encoding (UTF-8) and directory creation.
class FileWriter {
  final FileSystem fileSystem;

  FileWriter(this.fileSystem);

  /// Write an HTML document to a file.
  Future<void> writeHtml(String path, Document doc) async {
    final content = doc.outerHtml;
    await writeString(path, content);
  }

  /// Write a string to a file.
  /// Creates parent directories as needed.
  Future<void> writeString(String path, String content) async {
    final file = File(path);

    // Ensure parent directory exists
    await file.parent.create(recursive: true);

    // Write with UTF-8 encoding
    await file.writeAsString(content, encoding: const Utf8Codec());
  }
}
