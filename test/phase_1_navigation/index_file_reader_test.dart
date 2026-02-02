import 'package:test/test.dart';
import 'package:ebook_html_converter/phase_1_navigation/index_file_reader.dart';
import 'package:ebook_html_converter/phase_1_navigation/library_index_parser.dart';
import 'package:ebook_html_converter/phase_1_navigation/file_system.dart';

class MockFileSystem implements FileSystem {
  final Map<String, String> files = {};

  @override
  Future<String> readFile(String path) async {
    if (!files.containsKey(path)) {
      throw Exception('File not found: $path');
    }
    return files[path]!;
  }

  @override
  Future<bool> fileExists(String path) async {
    return files.containsKey(path);
  }

  @override
  String resolvePath(String base, String relative) {
    return '$base/$relative';
  }
}

void main() {
  group('IndexFileReader', () {
    late MockFileSystem fileSystem;
    late LibraryIndexParser parser;
    late IndexFileReader reader;

    setUp(() {
      fileSystem = MockFileSystem();
      parser = LibraryIndexParser();
      reader = IndexFileReader(fileSystem, parser);
    });

    test('reads and parses a valid index file', () async {
      fileSystem.files['test.html'] = '''
        <html>
        <script>
        AddIndex("Chapter 1", "chapter1.html", "book");
        AddIndex("Folder A", "folderA/", "folder");
        </script>
        </html>
      ''';

      final index = await reader.readIndex('test.html');

      expect(index.items, hasLength(2));
      expect(index.items[0].name, equals('Chapter 1'));
      expect(index.items[0].path, equals('chapter1.html'));
      expect(index.items[0].type, equals(IndexItemType.book));
      expect(index.items[1].name, equals('Folder A'));
      expect(index.items[1].path, equals('folderA/'));
      expect(index.items[1].type, equals(IndexItemType.folder));
    });

    test('throws exception when file does not exist', () async {
      expect(
        () => reader.readIndex('nonexistent.html'),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty index for file with no AddIndex calls', () async {
      fileSystem.files['empty.html'] =
          '<html><body>No index here</body></html>';

      final index = await reader.readIndex('empty.html');

      expect(index.items, isEmpty);
    });

    test('handles all index item types', () async {
      fileSystem.files['all_types.html'] = '''
        AddIndex("Folder", "folder/", "folder");
        AddIndex("Book", "book.html", "book");
        AddIndex("Splited", "split.html", "splited_book");
        AddIndex("Start", "start.html", "book_start");
        AddIndex("Mid", "mid.html", "book_mid");
        AddIndex("End", "end.html", "book_end");
        AddIndex("All", "all.html", "all_book");
      ''';

      final index = await reader.readIndex('all_types.html');

      expect(index.items, hasLength(7));
      expect(index.items[0].type, equals(IndexItemType.folder));
      expect(index.items[1].type, equals(IndexItemType.book));
      expect(index.items[2].type, equals(IndexItemType.splitedBook));
      expect(index.items[3].type, equals(IndexItemType.bookStart));
      expect(index.items[4].type, equals(IndexItemType.bookMid));
      expect(index.items[5].type, equals(IndexItemType.bookEnd));
      expect(index.items[6].type, equals(IndexItemType.allBook));
    });

    test('handles AddIndex with varying whitespace', () async {
      fileSystem.files['whitespace.html'] = '''
        AddIndex( "Spaced" , "path.html" , "book" );
        AddIndex("NoSpace","path2.html","folder");
      ''';

      final index = await reader.readIndex('whitespace.html');

      expect(index.items, hasLength(2));
      expect(index.items[0].name, equals('Spaced'));
      expect(index.items[1].name, equals('NoSpace'));
    });
  });
}
