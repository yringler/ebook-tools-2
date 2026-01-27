import 'package:html/dom.dart';
import '../phase_1_navigation/table_of_contents.dart';
import 'content_section_extractor.dart';
import 'section_file_mapper.dart';

/// Splits book HTML into separate files per section.
/// Coordinates section extraction with consistent filename mapping.
class SectionSplitter {
  final ContentSectionExtractor extractor;
  final SectionFileMapper fileMapper;

  SectionSplitter(this.extractor, this.fileMapper);

  /// Split a document into sections based on TOC structure.
  /// Returns a map of filename → HTML Element for each section.
  Map<String, Element> splitIntoSections(Document doc, TableOfContents toc) {
    final sections = <String, Element>{};

    for (final item in toc.items) {
      if (item is GroupItem) {
        _splitGroupItem(doc, item, sections);
      } else if (item is ContentItem) {
        _splitContentItem(doc, item, sections);
      }
    }

    return sections;
  }

  void _splitGroupItem(
      Document doc, GroupItem group, Map<String, Element> sections) {
    for (final child in group.children) {
      if (child is ContentItem) {
        _splitContentItem(doc, child, sections);
      } else if (child is GroupItem) {
        _splitGroupItem(doc, child, sections);
      }
    }
  }

  void _splitContentItem(
      Document doc, ContentItem item, Map<String, Element> sections) {
    if (item.section.anchor.isNotEmpty) {
      final element = extractor.extractSection(doc, item.section.anchor);
      if (element != null) {
        final filename = fileMapper.getFilenameForSection(item.section);
        sections[filename] = element;
      }
    }
  }
}
