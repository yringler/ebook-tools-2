import 'dart:io';

/// Types of items that can appear in an index
enum IndexItemType {
  folder,
  book,
  splitedBook,
  bookStart,
  bookMid,
  bookEnd,
  allBook,
}

/// Represents a single item in an index (table of contents)
class IndexItem {
  final String name;
  final String path;
  final IndexItemType type;

  IndexItem({
    required this.name,
    required this.path,
    required this.type,
  });

  @override
  String toString() => 'IndexItem(name: $name, path: $path, type: $type)';
}

/// Represents an index page containing a list of items
class Index {
  final List<IndexItem> items;

  Index(this.items);

  @override
  String toString() => 'Index(items: $items)';
}

/// Parser for library index HTML files
class LibraryIndexParser {
  /// Parses an HTML file and extracts index items from AddIndex() calls
  Future<Index> parse(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('HTML file not found', filePath);
    }

    final content = await file.readAsString();
    final items = <IndexItem>[];

    // Match AddIndex("name", "path", "type") patterns
    final regex = RegExp(r'AddIndex\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)');

    for (final match in regex.allMatches(content)) {
      final name = match.group(1)!;
      final path = match.group(2)!;
      final typeStr = match.group(3)!;

      items.add(IndexItem(
        name: name,
        path: path,
        type: _parseType(typeStr),
      ));
    }

    return Index(items);
  }

  IndexItemType _parseType(String typeStr) {
    switch (typeStr) {
      case 'folder':
        return IndexItemType.folder;
      case 'book':
        return IndexItemType.book;
      case 'splited_book':
        return IndexItemType.splitedBook;
      case 'book_start':
        return IndexItemType.bookStart;
      case 'book_mid':
        return IndexItemType.bookMid;
      case 'book_end':
        return IndexItemType.bookEnd;
      case 'all_book':
        return IndexItemType.allBook;
      default:
        throw ArgumentError('Unknown index item type: $typeStr');
    }
  }
}
