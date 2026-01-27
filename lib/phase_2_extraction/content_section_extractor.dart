import 'package:html/dom.dart';

/// Extracts HTML content between specific anchors.
/// Stateless utility for finding and extracting complete HTML elements.
class ContentSectionExtractor {
  /// Extract content between two anchor points in a document.
  /// Returns the complete HTML element at the start anchor.
  Element? extractSection(Document doc, String anchorName) {
    final anchor = _findAnchorElement(doc, anchorName);
    if (anchor == null) return null;

    // Find the nearest parent element that contains substantial content
    return _findContentContainer(anchor);
  }

  /// Extract content between a start and end anchor.
  /// Returns the range of elements between the anchors.
  Element? extractSectionRange(
      Document doc, String startAnchor, String endAnchor) {
    final startElement = extractSection(doc, startAnchor);
    if (startElement == null) return null;

    final endElement = _findAnchorElement(doc, endAnchor);
    if (endElement == null) return startElement;

    // For now, return the start element
    // In a full implementation, would collect all elements between start and end
    return startElement;
  }

  Element? _findAnchorElement(Document doc, String anchorName) {
    try {
      return doc.getElementById(anchorName);
    } catch (e) {
      return null;
    }
  }

  Element? _findContentContainer(Element anchor) {
    var current = anchor;
    while (current.parent != null) {
      if (current.localName == 'div' || current.localName == 'section') {
        return current;
      }
      current = current.parent!;
    }
    return anchor;
  }
}
