# BookNavigator

A class for navigating through offline HTML book structures by following links based on heading text or link text matching.

## Overview

The `BookNavigator` allows you to programmatically navigate through a collection of linked HTML files (like an offline ebook or documentation) by providing a path of text strings that match headings or link text.

## Features

- **Path-based navigation**: Navigate using a list of strings representing the navigation path
- **Flexible matching**: Matches against link text, heading text, or headings containing links
- **Case-insensitive**: Optional case-insensitive matching (default)
- **Whitespace handling**: Automatic whitespace trimming for reliable matching
- **Relative path resolution**: Handles relative links between HTML files
- **Error handling**: Clear exceptions when navigation fails
- **Exploration helpers**: Methods to discover available links at any level

## Basic Usage

```dart
import 'package:ebook_tools_2/book_navigator.dart';

void main() async {
  // Create navigator pointing to root index.html
  final navigator = BookNavigator('path/to/index.html');

  // Navigate using a path of link/heading texts
  final document = await navigator.navigateTo([
    'Chapter 1',
    'Section 1.2',
    'Subsection 1.2.3'
  ]);

  // Access the parsed HTML document
  print(document.querySelector('h1')?.text);
}
```

## Constructor

```dart
BookNavigator(
  String rootIndexPath, {
  bool caseSensitive = false,
  bool trimWhitespace = true,
})
```

### Parameters

- **`rootIndexPath`**: Path to the root index.html file (absolute or relative)
- **`caseSensitive`**: Whether link matching should be case-sensitive (default: `false`)
- **`trimWhitespace`**: Whether to trim whitespace when matching text (default: `true`)

## Methods

### `navigateTo(List<String> navigationPath)`

Navigates through the book structure following the given path.

**Parameters:**
- `navigationPath`: List of strings representing headings or link text to follow sequentially

**Returns:** `Future<Document>` - The parsed HTML document at the final destination

**Throws:**
- `NavigationException` - If any path segment cannot be found
- `FileSystemException` - If any HTML file cannot be read

**Example:**
```dart
final doc = await navigator.navigateTo(['Getting Started', 'Installation']);
```

### `navigateToHtml(List<String> navigationPath)`

Convenience method that returns the HTML content as a string instead of a Document object.

**Returns:** `Future<String>` - The HTML content as a string

**Example:**
```dart
final html = await navigator.navigateToHtml(['Chapter 1']);
print('HTML length: ${html.length}');
```

### `getAvailableLinks([List<String>? navigationPath])`

Retrieves all available navigation options (links and headings) from a document.

**Parameters:**
- `navigationPath`: Optional path to navigate to first. If omitted, returns links from root index.

**Returns:** `Future<List<String>>` - Sorted list of available link texts and heading texts

**Example:**
```dart
// Get links from root
final rootLinks = await navigator.getAvailableLinks();

// Get links after navigating to a specific page
final chapterLinks = await navigator.getAvailableLinks(['Chapter 1']);
```

## How Navigation Works

The navigator follows this process for each path segment:

1. **Parse current HTML file** (starting with root index.html)
2. **Search for matching links** in this order:
   - Direct links (`<a>` tags) with matching text
   - Headings (`<h1>`-`<h6>`) with matching text that contain links
   - Headings wrapped in links
   - Partial matches (contains or is contained by)
3. **Resolve the link's href** relative to the current file
4. **Navigate to the next file** and repeat for the next path segment
5. **Return the final document** after all path segments are processed

## Navigation Patterns

### Example HTML Structure

```
book/
├── index.html          (root)
├── chapter1/
│   ├── index.html      (Chapter 1 overview)
│   ├── section1.html   (Section 1.1)
│   └── section2.html   (Section 1.2)
└── chapter2/
    └── index.html
```

### Matching Behavior

Given this HTML in `index.html`:
```html
<h1><a href="chapter1/index.html">Chapter 1: Introduction</a></h1>
<a href="chapter2/index.html">Chapter 2</a>
```

These paths will match:
```dart
['Chapter 1: Introduction']  // Exact match
['Chapter 1']                // Partial match (case-insensitive)
['chapter 1']                // Case-insensitive
['Introduction']             // Partial match
['Chapter 2']                // Direct link match
```

## Error Handling

```dart
try {
  final doc = await navigator.navigateTo(['Nonexistent Chapter']);
} on NavigationException catch (e) {
  print('Could not find: ${e.message}');
  print('Failed at segment: ${e.segmentIndex}');
} on FileSystemException catch (e) {
  print('File not found: ${e.path}');
}
```

## Advanced Examples

### Interactive Navigation Helper

```dart
Future<void> interactiveNavigate(BookNavigator navigator) async {
  var currentPath = <String>[];

  while (true) {
    print('\nCurrent path: ${currentPath.join(' > ')}');

    final links = await navigator.getAvailableLinks(
      currentPath.isEmpty ? null : currentPath
    );

    print('Available links:');
    for (var i = 0; i < links.length; i++) {
      print('  $i. ${links[i]}');
    }

    // User selects a link...
    // Add to path and continue
  }
}
```

### Building a Table of Contents

```dart
Future<Map<String, dynamic>> buildTOC(
  BookNavigator navigator,
  [List<String> path = const []]
) async {
  final links = await navigator.getAvailableLinks(
    path.isEmpty ? null : path
  );

  final toc = <String, dynamic>{};

  for (final link in links) {
    final newPath = [...path, link];
    toc[link] = {
      'path': newPath,
      'children': await buildTOC(navigator, newPath),
    };
  }

  return toc;
}
```

### Searching for Content

```dart
Future<String?> findPageContaining(
  BookNavigator navigator,
  String searchText,
  [List<String> currentPath = const []]
) async {
  final doc = await navigator.navigateTo(currentPath);

  if (doc.body?.text.contains(searchText) ?? false) {
    return currentPath.join(' > ');
  }

  final links = await navigator.getAvailableLinks(currentPath);

  for (final link in links) {
    final found = await findPageContaining(
      navigator,
      searchText,
      [...currentPath, link]
    );
    if (found != null) return found;
  }

  return null;
}
```

## Testing

The BookNavigator can be tested with mock HTML files:

```dart
// Create test HTML files
final testDir = Directory.systemTemp.createTempSync('book_test');
File('${testDir.path}/index.html').writeAsStringSync('''
  <html><body>
    <a href="chapter1.html">Chapter 1</a>
  </body></html>
''');
File('${testDir.path}/chapter1.html').writeAsStringSync('''
  <html><body>
    <h1>Chapter 1 Content</h1>
  </body></html>
''');

// Test navigation
final navigator = BookNavigator('${testDir.path}/index.html');
final doc = await navigator.navigateTo(['Chapter 1']);
assert(doc.querySelector('h1')?.text == 'Chapter 1 Content');
```

## Use Cases

- **Ebook processing**: Extract or transform content from offline HTML books
- **Documentation scrapers**: Navigate through HTML documentation programmatically
- **Content extraction**: Pull specific sections from large HTML document collections
- **Link validation**: Verify all internal links work correctly
- **TOC generation**: Build table of contents from HTML structure
- **Content migration**: Extract content for conversion to other formats
