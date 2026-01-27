import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import '../library_index_parser.dart';
import '../table_of_contents.dart';
import 'file_system.dart';

/// Loads and parses an index HTML file.
/// Coordinates reading from disk and parsing with LibraryIndexParser.
class IndexFileReader {
  final FileSystem fileSystem;
  final LibraryIndexParser parser;

  IndexFileReader(this.fileSystem, this.parser);

  /// Read an index HTML file and parse it.
  Future<Index> readIndex(String filePath) async {
    final content = await fileSystem.readFile(filePath);
    final document = html_parser.parse(content);
    return parser.parse(document);
  }
}
