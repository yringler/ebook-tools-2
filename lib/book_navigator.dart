import 'dart:io';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:path/path.dart' as path;

/// Exception thrown when navigation fails
class NavigationException implements Exception {
  final String message;
  NavigationException(this.message);

  @override
  String toString() => 'NavigationException: $message';
}

/// Navigates through offline HTML book structure by following a path
/// of strings that match headings or link text
class BookNavigator {
  final String rootIndexPath;

  BookNavigator(this.rootIndexPath);

  /// Navigates through the book following the given path
  ///
  /// [path] - List of strings representing headings or link text to follow
  ///
  /// Returns the parsed HTML Document at the final destination
  Future<Document> navigateTo(List<String> path) async {
    String currentFilePath = rootIndexPath;
    Document currentDocument = await _parseHtmlFile(currentFilePath);

    for (final pathSegment in path) {
      // TODO: Implement logic to find matching link/heading in currentDocument
      // - Search through headings (h1-h6) for matching text
      // - Search through links (<a> tags) for matching text
      // - Determine the matching strategy (exact, partial, case-sensitive, etc.)
      final nextHref = _findMatchingLink(currentDocument, pathSegment);

      if (nextHref == null) {
        throw NavigationException(
            'Could not find link matching "$pathSegment"');
      }

      // Resolve the next file path relative to current file
      currentFilePath = _resolveHtmlPath(currentFilePath, nextHref);
      currentDocument = await _parseHtmlFile(currentFilePath);
    }

    return currentDocument;
  }

  /// Finds a link in the document that matches the target text
  ///
  /// Returns the href attribute if found, null otherwise
  String? _findMatchingLink(Document document, String targetText) {
    // TODO: Implement matching logic based on actual HTML structure
    // Need to understand:
    // - How are headings structured in the HTML?
    // - Are links inside headings or separate?
    // - What text matching strategy works best?
    // - Should matching be case-sensitive?

    return null;
  }

  /// Resolves an HTML file path relative to the current file
  String _resolveHtmlPath(String currentFilePath, String href) {
    // Remove fragment/query from href
    final cleanHref = href.split('#').first.split('?').first;

    final currentDir = path.dirname(currentFilePath);
    return path.normalize(path.join(currentDir, cleanHref));
  }

  /// Parses an HTML file and returns the Document
  Future<Document> _parseHtmlFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('HTML file not found', filePath);
    }

    final htmlContent = await file.readAsString();
    return parser.parse(htmlContent);
  }
}
