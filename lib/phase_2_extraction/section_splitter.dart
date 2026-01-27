import 'package:html/dom.dart';
import '../table_of_contents.dart';
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

  void _splitGroupItem(Document doc, GroupItem group, Map<String, Element> sections) {
    for (final section in group.sections) {
      _splitContentSection(doc, section, sections);
    }
  }

  void _splitContentSection(
    Document doc,
    ContentSection section,
    Map<String, Element> sections,
  ) {
    for (final item in section.items) {
      _splitContentItem(doc, item, sections);
    }
  }

  void _splitContentItem(Document doc, ContentItem item, Map<String, Element> sections) {
    if (item.anchorId != null && item.anchorId!.isNotEmpty) {
      final element = extractor.extractSection(doc, item.anchorId!);
      if (element != null) {
        final filename = fileMapper.getFilenameForSection(item);
        sections[filename] = element;
      }
    }
  }
}
