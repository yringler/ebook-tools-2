import 'package:html/dom.dart';
import '../table_of_contents.dart';
import '../phase_2_extraction/section_file_mapper.dart';

/// Updates anchor hrefs when splitting HTML into multiple files.
/// Rewrites internal links to point to correct files.
class AnchorRewriter {
  final SectionFileMapper fileMapper;

  AnchorRewriter(this.fileMapper);

  /// Rewrite all anchors in a document for split sections.
  Document rewriteAnchors(Document doc, TableOfContents toc) {
    final mapping = fileMapper.mapAllSections(toc);

    for (final anchor in doc.querySelectorAll('a[href]')) {
      final href = anchor.attributes['href'] ?? '';

      if (href.startsWith('#')) {
        // Internal anchor reference
        final anchorId = href.substring(1);
        final targetFile = _findFileForAnchor(mapping, anchorId);

        if (targetFile != null) {
          anchor.attributes['href'] = '$targetFile#$anchorId';
        }
      }
      // External links are left unchanged
    }

    return doc;
  }

  String? _findFileForAnchor(Map<ContentItem, String> mapping, String anchorId) {
    for (final entry in mapping.entries) {
      if (entry.key.anchorId == anchorId) {
        return entry.value;
      }
    }
    return null;
  }
}
