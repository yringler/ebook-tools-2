import 'dart:io';
import 'library_index_parser.dart';
import 'file_system.dart';

/// Loads and parses an index HTML file.
/// Coordinates reading from disk and parsing with LibraryIndexParser.
class IndexFileReader {
  final FileSystem fileSystem;
  final LibraryIndexParser parser;

  IndexFileReader(this.fileSystem, this.parser);

  /// Read an index HTML file and parse it.
  Future<Index> readIndex(String filePath) async {
    if (!await fileSystem.fileExists(filePath)) {
      throw FileSystemException('Index file not found', filePath);
    }

    final content = await fileSystem.readFile(filePath);
    return parser.parseContent(content);
  }
}
