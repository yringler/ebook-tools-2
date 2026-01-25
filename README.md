# Ebook HTML Tools

A Dart toolkit for working with offline HTML ebooks, providing tools to navigate and convert HTML book structures.

## Features

### 1. BookNavigator

Navigate through offline HTML book structures by following a path of strings that match headings or link text.

**Example:**
```dart
import 'package:ebook_tools_2/library_index_parser.dart';

final navigator = BookNavigator('path/to/index.html');
final document = await navigator.navigateTo(['Chapter 1', 'Section 1.2']);
```

### 2. HTML Converter

Convert source HTML files into clean, ebook-ready HTML suitable for conversion with Calibre.

## Setup

Source HTML has to be download from [a dropbox mirror](https://www.dropbox.com/scl/fi/54u7gihw1q0p3bk50dxkv/online.zip?rlkey=7ev329lfxlehwoye490zh0ehv&st=mzvzy60f&dl=0) for [torat emet freeware](https://www.toratemetfreeware.com/files/online.zip), extracted, and moved to this repo under `source/torat-emet`.
Find the link [here](https://www.toratemetfreeware.com/?dbases;1;html)

It will be read from there.

## Usage

Run the HTML converter:
```bash
dart run bin/ebook_html_converter.dart -i input.html -o output/
```

Use the BookNavigator in your code:
```dart
import 'package:ebook_tools_2/library_index_parser.dart';

final navigator = BookNavigator('book/index.html');
final doc = await navigator.navigateTo(['Chapter 1']);
```
