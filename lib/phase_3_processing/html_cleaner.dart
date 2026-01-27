import 'package:html/dom.dart';

/// Removes unwanted elements from HTML.
/// Stateless utility for cleaning documents and elements.
class HtmlCleaner {
  static const _unwantedTags = ['script', 'style', 'nav', 'noscript'];

  /// Clean a document by removing unwanted elements.
  Document clean(Document doc) {
    for (final tag in _unwantedTags) {
      for (final e in doc.querySelectorAll(tag)) {
        e.remove();
      }
    }
    return doc;
  }

  /// Clean an individual element by removing unwanted children.
  Element cleanElement(Element element) {
    for (final tag in _unwantedTags) {
      for (final e in element.querySelectorAll(tag)) {
        e.remove();
      }
    }

    // Remove navigation elements
    for (final e in element.querySelectorAll('[role="navigation"]')) {
      e.remove();
    }
    for (final e in element.querySelectorAll('.nav, .navbar, .menu')) {
      e.remove();
    }

    // Strip unnecessary attributes
    _stripAttributes(element);

    return element;
  }

  void _stripAttributes(Element element) {
    final attributesToKeep = ['id', 'class', 'href', 'src', 'alt', 'title'];

    for (final e in element.querySelectorAll('*')) {
      final keysToRemove = <String>[];

      for (final key in e.attributes.keys) {
        final keyStr = key.toString();
        if (!attributesToKeep.contains(keyStr)) {
          keysToRemove.add(keyStr);
        }
      }

      for (final key in keysToRemove) {
        e.attributes.remove(key);
      }
    }
  }
}
