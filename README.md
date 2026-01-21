# Ebook HTML Tools

A Dart toolkit for working with offline HTML ebooks, providing tools to navigate and convert HTML book structures.

## Features

### 1. BookNavigator

Navigate through offline HTML book structures programmatically by following links based on heading or link text.

**Key capabilities:**
- Path-based navigation using text matching
- Case-insensitive and whitespace-tolerant matching
- Relative path resolution between HTML files
- Link discovery and exploration
- Comprehensive error handling

**Example:**
```dart
import 'package:ebook_tools_2/book_navigator.dart';

final navigator = BookNavigator('path/to/index.html');
final document = await navigator.navigateTo(['Chapter 1', 'Section 1.2']);
```

See [lib/book_navigator_README.md](lib/book_navigator_README.md) for detailed documentation.

### 2. HTML Converter

Convert source HTML files into clean, ebook-ready HTML suitable for conversion with Calibre.

## Setup

Source HTML has to be download from [torat emet free ware](https://www.toratemetfreeware.com/files/online.zip), extracted, and moved to this repo under `source/torat-emet`.
Find the link [here](https://www.toratemetfreeware.com/?dbases;1;html)
It will be read from there.

## Usage

Run the HTML converter:
```bash
dart run bin/ebook_html_converter.dart -i input.html -o output/
```

Use the BookNavigator in your code:
```dart
import 'package:ebook_tools_2/book_navigator.dart';

final navigator = BookNavigator('book/index.html');
final doc = await navigator.navigateTo(['Chapter 1']);
```