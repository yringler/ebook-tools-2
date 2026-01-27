import '../table_of_contents.dart';

/// Maps TOC sections to output filenames.
/// Generates unique, consistent filenames from ContentItem sections.
class SectionFileMapper {
  /// Get a filename for a section.
  /// Uses anchor name if available, otherwise sanitizes the title.
  String getFilenameForSection(ContentItem item) {
    if (item.anchorId != null && item.anchorId!.isNotEmpty) {
      return '${item.anchorId}.html';
    }

    // Sanitize title for filesystem
    final sanitized = item.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '$sanitized.html';
  }

  /// Generate a mapping of all sections in a TOC to their filenames.
  Map<ContentItem, String> mapAllSections(TableOfContents toc) {
    final mapping = <ContentItem, String>{};

    for (final group in toc.items) {
      if (group is GroupItem) {
        _mapGroupItems(group, mapping);
      } else if (group is ContentItem) {
        mapping[group] = getFilenameForSection(group);
      }
    }

    return mapping;
  }

  void _mapGroupItems(GroupItem group, Map<ContentItem, String> mapping) {
    for (final section in group.sections) {
      mapping[section] = getFilenameForSection(section);

      for (final item in section.items) {
        mapping[item] = getFilenameForSection(item);
      }
    }
  }
}
