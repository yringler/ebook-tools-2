import 'package:html/dom.dart';

/// Standardizes inline styles for Calibre compatibility.
/// Stateless utility for normalizing style attributes.
class StyleNormalizer {
  static const _unsupportedProperties = [
    'position',
    'float',
    'display',
    'z-index',
  ];

  /// Normalize styles throughout a document.
  Document normalize(Document doc) {
    for (final element in doc.querySelectorAll('*')) {
      if (element.attributes.containsKey('style')) {
        element.attributes['style'] =
            normalizeStyleAttribute(element.attributes['style']!);
      }
    }
    return doc;
  }

  /// Normalize a single style attribute value.
  String normalizeStyleAttribute(String style) {
    if (style.isEmpty) return '';

    final properties = <String>[];
    final pairs = style.split(';');

    for (final pair in pairs) {
      if (pair.isEmpty) continue;

      final parts = pair.split(':');
      if (parts.length != 2) continue;

      final key = parts[0].trim().toLowerCase();
      final value = parts[1].trim();

      if (_unsupportedProperties.contains(key)) {
        continue; // Skip unsupported properties
      }

      properties.add('$key: $value');
    }

    return properties.join('; ');
  }
}
