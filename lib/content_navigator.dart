import 'dart:io';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Represents a section within a book's content
class ContentSection {
  final String title;
  final String anchor;
  final DocumentFragment content;

  ContentSection({
    required this.title,
    required this.anchor,
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

    final content = await file.readAsString();
    final document = html_parser.parse(content);

    // Extract the nested table of contents from the beginning of the document
    final tocItems = _extractNestedToc(document);

    return ContentNavigator(TableOfContents(tocItems));
  }

  /// Extracts nested TOC structure from HTML document
  ///
  /// Works for various Jewish text types (Bible, Talmud, Mishna, Chassidus, etc.)
  /// Structure: Sections (L99 anchors) > Subsections (L2 anchors)
  /// - Bible: Parshiot > Chapters
  /// - Talmud: Tractates/Sections > Pages/Folios
  /// - Mishna: Tractates > Chapters
  /// - Other texts: Custom hierarchies following same anchor pattern
  static List<TableOfContentsItem> _extractNestedToc(Document document) {
    final items = <TableOfContentsItem>[];

    // Find all top-level sections - they have anchors ending with _L99
    // Pattern: <a name="HtmpReportNum####_L99"></a>
    final anchors = document.querySelectorAll('a[name]');

    for (final anchor in anchors) {
      final anchorName = anchor.attributes['name'] ?? '';

      // Skip if not a section TOC anchor (must end with _L99)
      if (!anchorName.endsWith('_L99')) continue;

      // Find the link to the section content (next sibling or nearby)
      // Pattern: <a href="#HtmpReportNum####_L5">Title</a>
      final sectionLink = _findNextLink(anchor);
      if (sectionLink == null) continue;

      final sectionTitle = sectionLink.text.trim();
      final sectionAnchor = sectionLink.attributes['href']?.substring(1) ?? '';

      // Find the table with subsection links (should be next sibling structure)
      final table = _findNextTable(anchor);
      final subsections = <TableOfContentsItem>[];

      if (table != null) {
        // Extract subsection links from the table
        final subsectionLinks = table.querySelectorAll('a[href]');
        for (final link in subsectionLinks) {
          final href = link.attributes['href'] ?? '';
          if (href.startsWith('#') && href.contains('_L2')) {
            final subsectionTitle = link.text.trim();
            final subsectionAnchor = href.substring(1);

            // Create a ContentItem for each subsection
            // (content will be extracted when needed)
            subsections.add(ContentItem(
              title: subsectionTitle,
              section: ContentSection(
                title: subsectionTitle,
                anchor: subsectionAnchor,
                content: DocumentFragment(),
              ),
            ));
          }
        }
      }

      // Create a GroupItem for the section with its subsections
      if (sectionTitle.isNotEmpty) {
        items.add(GroupItem(
          title: sectionTitle,
          children: subsections,
        ));
      }
    }

    return items;
  }

  /// Find the next <a> link element after the given element
  static Element? _findNextLink(Element element) {
    var next = element.nextElementSibling;

    // Search through next siblings
    while (next != null) {
      if (next.localName == 'a' && next.attributes.containsKey('href')) {
        return next;
      }
      // Also check children of next element
      final childLink = next.querySelector('a[href]');
      if (childLink != null) return childLink;

      next = next.nextElementSibling;

      // Stop searching after a few siblings to avoid going too far
      if (next?.localName == 'table' || next?.localName == 'hr') break;
    }

    return null;
  }

  /// Find the next <table> element after the given element
  static Element? _findNextTable(Element element) {
    var next = element.nextElementSibling;

    // Search through next siblings
    while (next != null) {
      if (next.localName == 'table') {
        return next;
      }
      // Also check children
      final childTable = next.querySelector('table');
      if (childTable != null) return childTable;

      next = next.nextElementSibling;

      // Stop searching after encountering another anchor (next section)
      final nextAnchor = next?.querySelector('a[name]');
      if (nextAnchor != null &&
          (nextAnchor.attributes['name']?.endsWith('_L99') ?? false)) {
        break;
      }
    }

    // The table may be a sibling of the parent element (e.g. anchor is inside a span)
    final parent = element.parent;
    if (parent != null && parent.localName != 'body') {
      return _findNextTable(parent);
    }

    return null;
  }
}
