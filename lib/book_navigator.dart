import 'dart:io';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:path/path.dart' as path;

/// Exception thrown when navigation fails to find a matching link
class NavigationException implements Exception {
  final String message;
  final List<String> pathSegment;
  final int segmentIndex;

  NavigationException(this.message, this.pathSegment, this.segmentIndex);

  @override
  String toString() =>
      'NavigationException: $message (at path segment $segmentIndex: "${pathSegment[segmentIndex]}")';
}

/// Navigates through offline HTML book structure by following links
/// based on heading text or link text matching
class BookNavigator {
  final String rootIndexPath;
  final bool caseSensitive;
  final bool trimWhitespace;

  /// Creates a new BookNavigator
  ///
  /// [rootIndexPath] - Absolute or relative path to the root index.html file
  /// [caseSensitive] - Whether link matching should be case-sensitive (default: false)
  /// [trimWhitespace] - Whether to trim whitespace when matching (default: true)
  BookNavigator(
    this.rootIndexPath, {
    this.caseSensitive = false,
    this.trimWhitespace = true,
  });

  /// Navigates through the book structure following the given path
  ///
  /// [navigationPath] - List of strings representing headings or link text to follow
  ///
  /// Returns the parsed HTML Document at the final destination
  ///
  /// Throws [NavigationException] if any path segment cannot be found
  /// Throws [FileSystemException] if any HTML file cannot be read
  Future<Document> navigateTo(List<String> navigationPath) async {
    if (navigationPath.isEmpty) {
      // If path is empty, return the root index
      return await _parseHtmlFile(rootIndexPath);
    }

    String currentFilePath = rootIndexPath;
    Document currentDocument = await _parseHtmlFile(currentFilePath);

    for (int i = 0; i < navigationPath.length; i++) {
      final pathSegment = navigationPath[i];
      final nextHref = _findMatchingLink(currentDocument, pathSegment);

      if (nextHref == null) {
        throw NavigationException(
          'Could not find link matching "$pathSegment"',
          navigationPath,
          i,
        );
      }

      // Resolve the next file path relative to the current file
      currentFilePath = _resolveHtmlPath(currentFilePath, nextHref);
      currentDocument = await _parseHtmlFile(currentFilePath);
    }

    return currentDocument;
  }

  /// Finds a link in the document that matches the given text
  ///
  /// Searches for matches in:
  /// 1. Link text (<a> element text content)
  /// 2. Heading text that contains a link
  ///
  /// Returns the href attribute if found, null otherwise
  String? _findMatchingLink(Document document, String targetText) {
    final normalizedTarget = _normalizeText(targetText);

    // First, try to find direct links with matching text
    final links = document.querySelectorAll('a[href]');
    for (final link in links) {
      final linkText = _normalizeText(link.text);
      if (linkText == normalizedTarget) {
        return link.attributes['href'];
      }
    }

    // Second, try to find headings that contain links with matching text
    final headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    for (final heading in headings) {
      final headingText = _normalizeText(heading.text);
      if (headingText == normalizedTarget) {
        // Check if this heading contains a link
        final linkInHeading = heading.querySelector('a[href]');
        if (linkInHeading != null) {
          return linkInHeading.attributes['href'];
        }
      }

      // Also check if the heading itself is wrapped in a link
      if (heading.parent?.localName == 'a') {
        final parentLink = heading.parent as Element;
        if (parentLink.attributes['href'] != null) {
          return parentLink.attributes['href'];
        }
      }
    }

    // Third, try partial matching - find links that contain the target text
    for (final link in links) {
      final linkText = _normalizeText(link.text);
      if (linkText.contains(normalizedTarget) || normalizedTarget.contains(linkText)) {
        return link.attributes['href'];
      }
    }

    return null;
  }

  /// Normalizes text for comparison based on settings
  String _normalizeText(String text) {
    var normalized = text;
    if (trimWhitespace) {
      normalized = normalized.trim();
    }
    if (!caseSensitive) {
      normalized = normalized.toLowerCase();
    }
    return normalized;
  }

  /// Resolves an HTML file path relative to the current file
  String _resolveHtmlPath(String currentFilePath, String href) {
    // Remove any fragment/query from href
    final cleanHref = href.split('#').first.split('?').first;

    // Get the directory of the current file
    final currentDir = path.dirname(currentFilePath);

    // Resolve the next path relative to current directory
    final resolvedPath = path.normalize(path.join(currentDir, cleanHref));

    return resolvedPath;
  }

  /// Parses an HTML file and returns the Document
  Future<Document> _parseHtmlFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException(
        'HTML file not found',
        filePath,
      );
    }

    final htmlContent = await file.readAsString();
    return parser.parse(htmlContent);
  }

  /// Convenience method to get the HTML content as a string
  Future<String> navigateToHtml(List<String> navigationPath) async {
    final document = await navigateTo(navigationPath);
    return document.outerHtml;
  }

  /// Retrieves all available navigation options (links and headings) from a document
  ///
  /// Useful for debugging or displaying available paths
  Future<List<String>> getAvailableLinks([List<String>? navigationPath]) async {
    final document = navigationPath == null || navigationPath.isEmpty
        ? await _parseHtmlFile(rootIndexPath)
        : await navigateTo(navigationPath);

    final availableLinks = <String>{};

    // Get all link texts
    final links = document.querySelectorAll('a[href]');
    for (final link in links) {
      final text = link.text.trim();
      if (text.isNotEmpty) {
        availableLinks.add(text);
      }
    }

    // Get all heading texts
    final headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    for (final heading in headings) {
      final text = heading.text.trim();
      if (text.isNotEmpty) {
        availableLinks.add(text);
      }
    }

    return availableLinks.toList()..sort();
  }
}
