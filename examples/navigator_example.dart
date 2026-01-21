import 'dart:io';
import 'package:path/path.dart' as path;
import '../lib/book_navigator.dart';

/// Example demonstrating the BookNavigator usage
void main() async {
  // Example 1: Basic navigation
  print('=== Example 1: Basic Navigation ===\n');

  // Assuming we have a book structure like:
  // index.html -> Chapter 1 (chapter1.html) -> Section 1.1 (section1-1.html)

  final navigator = BookNavigator('examples/book/index.html');

  try {
    // Navigate to a specific section using a path
    final path = ['Chapter 1', 'Section 1.1'];
    final document = await navigator.navigateTo(path);

    print('Successfully navigated to: ${path.join(' > ')}');
    print('Page title: ${document.querySelector('title')?.text ?? 'No title'}');
    print('First paragraph: ${document.querySelector('p')?.text ?? 'No content'}\n');
  } on NavigationException catch (e) {
    print('Navigation failed: $e\n');
  } on FileSystemException catch (e) {
    print('File error: ${e.message} - ${e.path}\n');
  }

  // Example 2: Get available navigation options
  print('=== Example 2: Available Links ===\n');

  try {
    final availableLinks = await navigator.getAvailableLinks();
    print('Available links from index:');
    for (final link in availableLinks) {
      print('  - $link');
    }
    print('');
  } catch (e) {
    print('Could not get available links: $e\n');
  }

  // Example 3: Case-insensitive navigation
  print('=== Example 3: Case-Insensitive Navigation ===\n');

  final flexibleNavigator = BookNavigator(
    'examples/book/index.html',
    caseSensitive: false,  // Default behavior
    trimWhitespace: true,  // Default behavior
  );

  try {
    // These should all work with case-insensitive matching
    final paths = [
      ['chapter 1'],  // lowercase
      ['CHAPTER 1'],  // uppercase
      ['Chapter 1'],  // mixed case
    ];

    for (final testPath in paths) {
      final doc = await flexibleNavigator.navigateTo(testPath);
      print('✓ Successfully navigated using: "${testPath.first}"');
    }
    print('');
  } catch (e) {
    print('Navigation error: $e\n');
  }

  // Example 4: Get HTML as string
  print('=== Example 4: Get HTML Content ===\n');

  try {
    final htmlContent = await navigator.navigateToHtml(['Chapter 1']);
    print('HTML content length: ${htmlContent.length} characters');
    print('First 200 characters:');
    print(htmlContent.substring(0, 200.clamp(0, htmlContent.length)));
    print('...\n');
  } catch (e) {
    print('Could not get HTML: $e\n');
  }

  // Example 5: Multi-level navigation
  print('=== Example 5: Deep Navigation ===\n');

  try {
    // Navigate through multiple levels
    final deepPath = ['Part I', 'Chapter 2', 'Section 2.3', 'Subsection 2.3.1'];
    final document = await navigator.navigateTo(deepPath);

    print('Successfully navigated through ${deepPath.length} levels:');
    print('  ${deepPath.join(' → ')}');
    print('');
  } on NavigationException catch (e) {
    print('Deep navigation failed: $e\n');
  }

  // Example 6: Exploring navigation hierarchy
  print('=== Example 6: Exploring Hierarchy ===\n');

  try {
    // Start at root
    print('From root index:');
    var links = await navigator.getAvailableLinks();
    print('  Available: ${links.take(3).join(', ')}...\n');

    // Navigate to first level
    if (links.isNotEmpty) {
      final firstLink = links.first;
      print('After navigating to "$firstLink":');
      links = await navigator.getAvailableLinks([firstLink]);
      print('  Available: ${links.take(3).join(', ')}...\n');
    }
  } catch (e) {
    print('Exploration error: $e\n');
  }
}
