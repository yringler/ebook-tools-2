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

/// Parses and navigates actual book content files (book, book_start/mid/end, all_book)
class ContentNavigator {
  final List<ContentSection> sections;

  ContentNavigator(this.sections);

  /// Parses a content HTML file and extracts its sections
  static Future<ContentNavigator> parse(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Content file not found', filePath);
    }

    // ignore: unused_local_variable
    final content = await file.readAsString();
    final sections = <ContentSection>[];

    // TODO: Parse content and extract sections

    return ContentNavigator(sections);
  }

  /// Returns the table of contents (section titles)
  List<String> get tableOfContents => sections.map((s) => s.title).toList();

  /// Gets a section by index
  ContentSection? getSection(int index) {
    if (index < 0 || index >= sections.length) return null;
    return sections[index];
  }

  /// Gets a section by title
  ContentSection? getSectionByTitle(String title) {
    for (final section in sections) {
      if (section.title == title) return section;
    }
    return null;
  }
}
