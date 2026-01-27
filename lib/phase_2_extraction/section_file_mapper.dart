import 'package:ebook_html_converter/phase_1_navigation/table_of_contents.dart';

/// Maps TOC sections to output filenames.
/// Generates unique, consistent filenames from ContentItem sections.
class SectionFileMapper {
  /// Get a filename for a section.
  /// Uses anchor name if available, otherwise sanitizes the title.
  String getFilenameForSection(ContentSection section) {
    if (section.anchor.isNotEmpty) {
      return '${section.anchor}.html';
    }

    // Sanitize title for filesystem
    final sanitized = section.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '$sanitized.html';
  }

  /// Generate a mapping of all sections in a TOC to their filenames.
  Map<ContentItem, String> mapAllSections(TableOfContents toc) {
    final mapping = <ContentItem, String>{};

    for (final item in toc.items) {
      if (item is GroupItem) {
        _mapGroupItems(item, mapping);
      } else if (item is ContentItem) {
        mapping[item] = getFilenameForSection(item.section);
      }
    }

    return mapping;
  }

  void _mapGroupItems(GroupItem group, Map<ContentItem, String> mapping) {
    for (final child in group.children) {
      if (child is ContentItem) {
        mapping[child] = getFilenameForSection(child.section);
      } else if (child is GroupItem) {
        _mapGroupItems(child, mapping);
      }
    }
  }
}
