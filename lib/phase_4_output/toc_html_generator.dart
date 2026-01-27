import '../table_of_contents.dart';
import '../phase_1_navigation/book_reference.dart';
import '../phase_2_extraction/section_file_mapper.dart';

/// Creates clean index.html with TOC for Calibre.
/// Generates ebook-friendly HTML structure with proper formatting.
class TocHtmlGenerator {
  final SectionFileMapper fileMapper;

  TocHtmlGenerator(this.fileMapper);

  /// Generate a table of contents HTML document.
  String generate(TableOfContents toc, BookReference book) {
    final mapping = fileMapper.mapAllSections(toc);
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<title>${_escape(book.title)}</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: serif; }');
    buffer.writeln('h1 { text-align: center; }');
    buffer.writeln('ol { list-style-type: decimal; }');
    buffer.writeln('.group-title { font-weight: bold; margin-top: 1em; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    buffer.writeln('<h1>${_escape(book.title)}</h1>');
    buffer.writeln('<ol>');

    for (final item in toc.items) {
      if (item is GroupItem) {
        _generateGroupItem(buffer, item, mapping);
      } else if (item is ContentItem) {
        _generateContentItem(buffer, item, mapping);
      }
    }

    buffer.writeln('</ol>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  void _generateGroupItem(
    StringBuffer buffer,
    GroupItem group,
    Map<ContentItem, String> mapping,
  ) {
    buffer.writeln('<li class="group-title">${_escape(group.title)}');
    buffer.writeln('<ol>');

    for (final section in group.sections) {
      _generateContentSection(buffer, section, mapping);
    }

    buffer.writeln('</ol></li>');
  }

  void _generateContentSection(
    StringBuffer buffer,
    ContentSection section,
    Map<ContentItem, String> mapping,
  ) {
    buffer.writeln('<li>${_escape(section.title)}');
    buffer.writeln('<ol>');

    for (final item in section.items) {
      _generateContentItem(buffer, item, mapping);
    }

    buffer.writeln('</ol></li>');
  }

  void _generateContentItem(
    StringBuffer buffer,
    ContentItem item,
    Map<ContentItem, String> mapping,
  ) {
    final filename = mapping[item] ?? 'unknown.html';
    final linkText = item.title.isEmpty ? 'Untitled' : item.title;
    buffer.writeln('<li><a href="$filename">${_escape(linkText)}</a></li>');
  }

  String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
