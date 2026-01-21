# Ebook HTML Converter

A Dart command-line tool to convert source HTML files into clean, ebook-ready HTML suitable for conversion with Calibre.

## Features

- Removes web-specific elements (scripts, iframes, navigation, headers, footers)
- Cleans up excessive formatting and nested tags
- Removes HTML comments
- Strips unnecessary attributes
- Normalizes whitespace
- Ensures proper HTML structure for ebooks
- Processes single files or entire directories
- Preserves semantic HTML structure

## Installation

1. Ensure you have Dart SDK installed (version 3.0.0 or higher)
2. Clone this repository
3. Run `dart pub get` to install dependencies

## Usage

### Convert a single HTML file

```bash
dart run ebook_html_converter -i input.html -o output/
```

### Convert all HTML files in a directory

```bash
dart run ebook_html_converter -i source_html/ -o output/
```

### Options

- `-i, --input`: Input HTML file or directory (required)
- `-o, --output`: Output directory for converted files (required)
- `--clean-formatting`: Clean up excessive formatting tags (default: true)
- `--preserve-styles`: Preserve inline styles (default: false)
- `--remove-scripts`: Remove script tags (default: true)
- `-h, --help`: Show usage information

### Examples

Convert with default settings:
```bash
dart run ebook_html_converter -i book.html -o cleaned/
```

Preserve inline styles:
```bash
dart run ebook_html_converter -i book.html -o cleaned/ --preserve-styles
```

Keep formatting tags:
```bash
dart run ebook_html_converter -i book.html -o cleaned/ --no-clean-formatting
```

## What Gets Cleaned

The converter performs the following operations:

1. **Removes unwanted elements:**
   - Scripts (`<script>`, `<noscript>`)
   - Embedded content (`<iframe>`, `<object>`, `<embed>`)
   - Navigation elements (`<nav>`, `<header>`, `<footer>`)

2. **Cleans attributes:**
   - Keeps only essential attributes: `href`, `src`, `alt`, `title`, `id`, `class`
   - Removes event handlers, data attributes, and other web-specific attributes
   - Optionally preserves `style` attributes

3. **Formatting cleanup:**
   - Removes empty elements
   - Normalizes whitespace
   - Removes HTML comments
   - Cleans up nested spans and divs

4. **Ensures ebook structure:**
   - Adds UTF-8 charset meta tag
   - Ensures proper HTML document structure
   - Formats output for readability

## Use with Calibre

After converting your HTML files:

1. Import the converted HTML files into Calibre
2. Use Calibre's ebook-convert tool or GUI to convert to your desired format (EPUB, MOBI, etc.)
3. The cleaned HTML will result in better-formatted ebooks with smaller file sizes

```bash
# Example with Calibre CLI
ebook-convert output/book.html book.epub
```

## Development

### Running tests

```bash
dart test
```

### Project structure

```
ebook-html-converter/
├── bin/
│   └── ebook_html_converter.dart  # CLI entry point
├── lib/
│   └── html_converter.dart        # Core conversion logic
├── test/
│   └── html_converter_test.dart   # Unit tests
├── examples/
│   ├── input/                     # Example input files
│   └── output/                    # Example output files
├── pubspec.yaml
└── README.md
```

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
