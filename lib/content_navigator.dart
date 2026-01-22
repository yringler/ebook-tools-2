import 'dart:io';
import 'package:html/dom.dart';

/// Represents a section within a book's content
class ContentSection {
  final String title;
  final DocumentFragment content;

  ContentSection({
    required this.title,
    required this.content,
  });
}

/// A table of contents item - either a leaf pointing to content, or a group with children
sealed class TableOfContentsItem {
  String get title;
}

/// A leaf item that points to actual content
class ContentItem extends TableOfContentsItem {
  @override
  final String title;
  final ContentSection section;

  ContentItem({required this.title, required this.section});
}

/// A group item that contains nested items
class GroupItem extends TableOfContentsItem {
  @override
  final String title;
  final List<TableOfContentsItem> children;

  GroupItem({required this.title, required this.children});
}

/// Represents the full table of contents hierarchy
class TableOfContents {
  final List<TableOfContentsItem> items;

  TableOfContents(this.items);
}

/// Parses and navigates actual book content files (book, book_start/mid/end, all_book)
class ContentNavigator {
  final TableOfContents tableOfContents;

  ContentNavigator(this.tableOfContents);

  /// Parses a content HTML file and extracts its sections
  static Future<ContentNavigator> parse(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Content file not found', filePath);
    }

    // ignore: unused_local_variable
    final content = await file.readAsString();

    // TODO: Parse content and build table of contents

    return ContentNavigator(TableOfContents([]));
  }
}
