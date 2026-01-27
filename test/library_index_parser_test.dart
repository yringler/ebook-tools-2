import 'dart:io';
import 'package:ebook_html_converter/phase_1_navigation/library_index_parser.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('IndexItem', () {
    test('stores name, path, and type', () {
      final item = IndexItem(
        name: 'Test Book',
        path: 'test.html',
        type: IndexItemType.book,
      );

      expect(item.name, equals('Test Book'));
      expect(item.path, equals('test.html'));
      expect(item.type, equals(IndexItemType.book));
    });

    test('toString returns readable representation', () {
      final item = IndexItem(
        name: 'My Book',
        path: 'book.html',
        type: IndexItemType.folder,
      );

      expect(item.toString(), contains('My Book'));
      expect(item.toString(), contains('book.html'));
      expect(item.toString(), contains('folder'));
    });
  });

  group('LibraryIndexParser.parse', () {
    late Directory tempDir;
    late LibraryIndexParser parser;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('index_test_');
      parser = LibraryIndexParser();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('parses single AddIndex call', () async {
      final file = File(p.join(tempDir.path, 'test.html'));
      await file.writeAsString('''
        <script>
        AddIndex("תורה", "d_root__001_tora.html", "folder");
        </script>
      ''');

      final index = await parser.parse(file.path);

      expect(index.items, hasLength(1));
      expect(index.items[0].name, equals('תורה'));
      expect(index.items[0].path, equals('d_root__001_tora.html'));
      expect(index.items[0].type, equals(IndexItemType.folder));
    });

    test('parses multiple AddIndex calls', () async {
      final file = File(p.join(tempDir.path, 'test.html'));
      await file.writeAsString('''
        <script>
        AddIndex("First", "first.html", "folder");
        AddIndex("Second", "second.html", "book");
        AddIndex("Third", "third.html", "splited_book");
        </script>
      ''');

      final index = await parser.parse(file.path);

      expect(index.items, hasLength(3));
      expect(index.items[0].type, equals(IndexItemType.folder));
      expect(index.items[1].type, equals(IndexItemType.book));
      expect(index.items[2].type, equals(IndexItemType.splitedBook));
    });

    test('parses all IndexItemType values', () async {
      final file = File(p.join(tempDir.path, 'test.html'));
      await file.writeAsString('''
        AddIndex("a", "a.html", "folder");
        AddIndex("b", "b.html", "book");
        AddIndex("c", "c.html", "splited_book");
        AddIndex("d", "d.html", "book_start");
        AddIndex("e", "e.html", "book_mid");
        AddIndex("f", "f.html", "book_end");
        AddIndex("g", "g.html", "all_book");
      ''');

      final index = await parser.parse(file.path);

      expect(index.items, hasLength(7));
      expect(
          index.items.map((i) => i.type).toList(),
          equals([
            IndexItemType.folder,
            IndexItemType.book,
            IndexItemType.splitedBook,
            IndexItemType.bookStart,
            IndexItemType.bookMid,
            IndexItemType.bookEnd,
            IndexItemType.allBook,
          ]));
    });

    test('handles whitespace variations in AddIndex calls', () async {
      final file = File(p.join(tempDir.path, 'test.html'));
      await file.writeAsString('''
        AddIndex("a","a.html","folder");
        AddIndex( "b" , "b.html" , "book" );
        AddIndex(  "c"  ,  "c.html"  ,  "splited_book"  );
      ''');

      final index = await parser.parse(file.path);

      expect(index.items, hasLength(3));
    });

    test('returns empty index for file with no AddIndex calls', () async {
      final file = File(p.join(tempDir.path, 'test.html'));
      await file.writeAsString('<html><body>No index here</body></html>');

      final index = await parser.parse(file.path);

      expect(index.items, isEmpty);
    });

    test('throws FileSystemException for non-existent file', () async {
      expect(
        () => parser.parse(p.join(tempDir.path, 'nonexistent.html')),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws ArgumentError for unknown type', () async {
      final file = File(p.join(tempDir.path, 'test.html'));
      await file
          .writeAsString('AddIndex("test", "test.html", "unknown_type");');

      expect(
        () => parser.parse(file.path),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('LibraryIndexParser.parse with real sample files', () {
    final samplesDir = p.join(Directory.current.path, 'samples');
    late LibraryIndexParser parser;

    setUp(() {
      parser = LibraryIndexParser();
    });

    test('parses a_root.html (root index)', () async {
      final index = await parser.parse(p.join(samplesDir, 'a_root.html'));

      expect(index.items, isNotEmpty);
      // Root should contain folder items
      expect(
        index.items.any((item) => item.type == IndexItemType.folder),
        isTrue,
      );
    });

    test('parses d_root__001_tora.html (nested folder index)', () async {
      final index = await parser.parse(
        p.join(samplesDir, 'd_root__001_tora.html'),
      );

      expect(index.items, isNotEmpty);
    });

    test('parses d_root__001_tora__01_bereshit.html (book index)', () async {
      final index = await parser.parse(
        p.join(samplesDir, 'd_root__001_tora__01_bereshit.html'),
      );

      expect(index.items, isNotEmpty);
      // This index should contain actual books
      expect(
        index.items.any((item) =>
            item.type == IndexItemType.book ||
            item.type == IndexItemType.splitedBook),
        isTrue,
      );
    });

    test('content pages (f_*.html) have no index items', () async {
      // f_01683_part_1.html is a content page, not an index
      final index = await parser.parse(
        p.join(samplesDir, 'f_01683_part_1.html'),
      );

      expect(index.items, isEmpty);
    });
  });
}
