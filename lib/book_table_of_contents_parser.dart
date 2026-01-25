import 'package:html/dom.dart';
import 'table_of_contents.dart';

/// Extracts and builds the complete table of contents from book HTML content
class BookTableOfContentsParser {
  final Document document;

  BookTableOfContentsParser(this.document);

  /// Extracts nested TOC structure from HTML document
  ///
  /// Works for various Jewish text types (Bible, Talmud, Mishna, Chassidus, etc.)
  /// Structure: Sections (L99 anchors) > Subsections (L2 anchors)
  /// - Bible: Parshiot > Chapters
  /// - Talmud: Tractates/Sections > Pages/Folios
  /// - Mishna: Tractates > Chapters
  /// - Other texts: Custom hierarchies following same anchor pattern
  TableOfContents extractTableOfContents() {
    final items = <TableOfContentsItem>[];

    // Find all top-level sections - they have anchors ending with _L99
    // Pattern: <a name="HtmpReportNum####_L99"></a>
    final anchors = document.querySelectorAll('a[name\$="_L99"]');

    for (final anchor in anchors) {
      // Find the link to the section content (next sibling or nearby)
      // Pattern: <a href="#HtmpReportNum####_L5">Title</a>
      final sectionLink = _findNextLink(anchor);
      if (sectionLink == null) continue;

      final sectionTitle = sectionLink.text.trim();

      // Find the table with subsection links (should be next sibling structure)
      final table = _findNextTable(anchor);
      final subsections = <TableOfContentsItem>[];

      if (table != null) {
        // Extract subsection links from the table
        final subsectionLinks =
            table.querySelectorAll('a[href^="#"][href*="_L2"]');
        for (final link in subsectionLinks) {
          final href = link.attributes['href'] ?? '';
          final subsectionTitle = link.text.trim();
          final subsectionAnchor = href.substring(1);

          // Create a ContentItem for each subsection
          // (content will be extracted when needed)
          subsections.add(ContentItem(
            title: subsectionTitle,
            section: ContentSection(
              title: subsectionTitle,
              anchor: subsectionAnchor,
            ),
          ));
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

    return TableOfContents(items);
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
