import 'package:html/dom.dart';

/// Removes unwanted elements from HTML.
/// Stateless utility for cleaning documents and elements.
class HtmlCleaner {
  static const _unwantedTags = ['script', 'style', 'nav', 'noscript'];

  /// Clean a document by removing unwanted elements.
  Document clean(Document doc) {
    for (final tag in _unwantedTags) {
      doc.querySelectorAll(tag).forEach((e) => e.remove());
    }
    return doc;
  }

  /// Clean an individual element by removing unwanted children.
  Element cleanElement(Element element) {
    for (final tag in _unwantedTags) {
      element.querySelectorAll(tag).forEach((e) => e.remove());
    }

    // Remove navigation elements
    element.querySelectorAll('[role="navigation"]').forEach((e) => e.remove());
    element.querySelectorAll('.nav, .navbar, .menu').forEach((e) => e.remove());

    // Strip unnecessary attributes
    _stripAttributes(element);

    return element;
  }

  void _stripAttributes(Element element) {
    final attributesToKeep = ['id', 'class', 'href', 'src', 'alt', 'title'];

    for (final e in element.querySelectorAll('*')) {
      final keysToRemove = <String>[];

      e.attributes.forEach((key, value) {
        if (!attributesToKeep.contains(key)) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((key) => e.attributes.remove(key));
    }
  }
}
