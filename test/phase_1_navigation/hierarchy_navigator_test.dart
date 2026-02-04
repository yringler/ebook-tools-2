import 'package:test/test.dart';
import 'package:ebook_html_converter/phase_1_navigation/hierarchy_navigator.dart';
import 'package:ebook_html_converter/phase_1_navigation/index_file_reader.dart';
import 'package:ebook_html_converter/phase_1_navigation/library_index_parser.dart';
import 'package:ebook_html_converter/phase_1_navigation/path_resolver.dart';
import 'package:ebook_html_converter/phase_1_navigation/file_system.dart';

class MockFileSystem implements FileSystem {
  final Map<String, String> files = {};

  @override
  Future<String> readFile(String path) async {
    final normalized = _normalizePath(path);
    if (!files.containsKey(normalized)) {
      throw Exception('File not found: $path');
    }
    return files[normalized]!;
  }

  @override
  Future<bool> fileExists(String path) async {
    return files.containsKey(_normalizePath(path));
  }

  @override
  String resolvePath(String base, String relative) {
    return '$base/$relative';
  }

  String _normalizePath(String path) {
    return path.replaceAll('\\', '/');
  }
}

void main() {
  group('HierarchyNavigator', () {
    late MockFileSystem fileSystem;
    late LibraryIndexParser parser;
    late IndexFileReader indexReader;
    late PathResolver pathResolver;
    late HierarchyNavigator navigator;

    setUp(() {
      fileSystem = MockFileSystem();
      parser = LibraryIndexParser();
      indexReader = IndexFileReader(fileSystem, parser);
      pathResolver = PathResolver(fileSystem);
      navigator = HierarchyNavigator(indexReader, pathResolver);
    });

    test('discovers books from a flat index', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("Book One", "book1.html", "book");
        AddIndex("Book Two", "book2.html", "book");
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, hasLength(2));
      expect(books[0].title, equals('Book One'));
      expect(books[0].filePath, contains('book1.html'));
      expect(books[0].type, equals(IndexItemType.book));
      expect(books[0].breadcrumbs, isEmpty);
      expect(books[1].title, equals('Book Two'));
      expect(books[1].filePath, contains('book2.html'));
    });

    test('discovers books inside a single folder', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("Torah", "torah/index.html", "folder");
      ''';
      fileSystem.files['/library/torah/index.html'] = '''
        AddIndex("Genesis", "genesis.html", "book");
        AddIndex("Exodus", "exodus.html", "book");
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, hasLength(2));
      expect(books[0].title, equals('Genesis'));
      expect(books[0].breadcrumbs, equals(['Torah']));
      expect(books[1].title, equals('Exodus'));
      expect(books[1].breadcrumbs, equals(['Torah']));
    });

    test('discovers books in nested folders', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("Torah", "torah/index.html", "folder");
      ''';
      fileSystem.files['/library/torah/index.html'] = '''
        AddIndex("Genesis", "genesis/index.html", "folder");
      ''';
      fileSystem.files['/library/torah/genesis/index.html'] = '''
        AddIndex("Bereshit", "bereshit.html", "book");
        AddIndex("Noach", "noach.html", "book");
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, hasLength(2));
      expect(books[0].title, equals('Bereshit'));
      expect(books[0].breadcrumbs, equals(['Torah', 'Genesis']));
      expect(books[1].title, equals('Noach'));
      expect(books[1].breadcrumbs, equals(['Torah', 'Genesis']));
    });

    test('discovers books across multiple folders at same level', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("Torah", "torah/index.html", "folder");
        AddIndex("Neviim", "neviim/index.html", "folder");
      ''';
      fileSystem.files['/library/torah/index.html'] = '''
        AddIndex("Genesis", "genesis.html", "book");
      ''';
      fileSystem.files['/library/neviim/index.html'] = '''
        AddIndex("Joshua", "joshua.html", "book");
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, hasLength(2));
      expect(books[0].title, equals('Genesis'));
      expect(books[0].breadcrumbs, equals(['Torah']));
      expect(books[1].title, equals('Joshua'));
      expect(books[1].breadcrumbs, equals(['Neviim']));
    });

    test('returns empty list for empty index', () async {
      fileSystem.files['/library/index.html'] = '''
        <html><body>No books here</body></html>
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, isEmpty);
    });

    test('returns empty list for folder with no books', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("Empty Folder", "empty/index.html", "folder");
      ''';
      fileSystem.files['/library/empty/index.html'] = '''
        <html><body>Nothing</body></html>
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, isEmpty);
    });

    test('handles mixed folders and books at same level', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("Intro Book", "intro.html", "book");
        AddIndex("Torah", "torah/index.html", "folder");
        AddIndex("Appendix", "appendix.html", "book");
      ''';
      fileSystem.files['/library/torah/index.html'] = '''
        AddIndex("Genesis", "genesis.html", "book");
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, hasLength(3));
      expect(books[0].title, equals('Intro Book'));
      expect(books[0].breadcrumbs, isEmpty);
      expect(books[1].title, equals('Genesis'));
      expect(books[1].breadcrumbs, equals(['Torah']));
      expect(books[2].title, equals('Appendix'));
      expect(books[2].breadcrumbs, isEmpty);
    });

    test('handles deeply nested folders (3+ levels)', () async {
      fileSystem.files['/lib/index.html'] = '''
        AddIndex("Level1", "l1/index.html", "folder");
      ''';
      fileSystem.files['/lib/l1/index.html'] = '''
        AddIndex("Level2", "l2/index.html", "folder");
      ''';
      fileSystem.files['/lib/l1/l2/index.html'] = '''
        AddIndex("Level3", "l3/index.html", "folder");
      ''';
      fileSystem.files['/lib/l1/l2/l3/index.html'] = '''
        AddIndex("Deep Book", "deep.html", "book");
      ''';

      final books = await navigator.discoverBooks('/lib/index.html');

      expect(books, hasLength(1));
      expect(books[0].title, equals('Deep Book'));
      expect(books[0].breadcrumbs, equals(['Level1', 'Level2', 'Level3']));
    });

    test('ignores non-folder non-book types at folder level', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("Book", "book.html", "book");
        AddIndex("Splited", "split.html", "splited_book");
        AddIndex("Start", "start.html", "book_start");
        AddIndex("Mid", "mid.html", "book_mid");
        AddIndex("End", "end.html", "book_end");
        AddIndex("All", "all.html", "all_book");
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, hasLength(1));
      expect(books[0].title, equals('Book'));
      expect(books[0].type, equals(IndexItemType.book));
    });

    test('preserves file paths correctly', () async {
      fileSystem.files['/root/index.html'] = '''
        AddIndex("Folder", "sub/index.html", "folder");
      ''';
      fileSystem.files['/root/sub/index.html'] = '''
        AddIndex("My Book", "books/mybook.html", "book");
      ''';

      final books = await navigator.discoverBooks('/root/index.html');

      expect(books, hasLength(1));
      expect(books[0].filePath, contains('sub'));
      expect(books[0].filePath, contains('books'));
      expect(books[0].filePath, contains('mybook.html'));
    });

    test('handles Hebrew folder and book names', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("תורה", "torah/index.html", "folder");
      ''';
      fileSystem.files['/library/torah/index.html'] = '''
        AddIndex("בראשית", "genesis/index.html", "folder");
      ''';
      fileSystem.files['/library/torah/genesis/index.html'] = '''
        AddIndex("פרשת בראשית", "bereshit.html", "book");
      ''';

      final books = await navigator.discoverBooks('/library/index.html');

      expect(books, hasLength(1));
      expect(books[0].title, equals('פרשת בראשית'));
      expect(books[0].breadcrumbs, equals(['תורה', 'בראשית']));
    });

    test('throws when root index file does not exist', () async {
      expect(
        () => navigator.discoverBooks('/nonexistent/index.html'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when referenced folder index does not exist', () async {
      fileSystem.files['/library/index.html'] = '''
        AddIndex("Missing", "missing/index.html", "folder");
      ''';

      expect(
        () => navigator.discoverBooks('/library/index.html'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
