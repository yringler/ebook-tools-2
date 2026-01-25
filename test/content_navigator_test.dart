import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:ebook_html_converter/content_navigator.dart';
import 'package:ebook_html_converter/book_content_navigation.dart';
import 'package:ebook_html_converter/table_of_contents.dart';

void main() {
  group('ContentNavigator', () {
    final samplesDir = p.join(Directory.current.path, 'samples');

    test('parses nested TOC structure with sections and subsections', () async {
      // f_00760.html is a Bible text (Genesis) with parshiot > chapters structure
      final file = File(p.join(samplesDir, 'f_00760.html'));
      final content = await file.readAsString();
      final document = html_parser.parse(content);
      final bookNav = BookContentNavigation(document);
      final toc = bookNav.extractTableOfContents();
      final navigator = ContentNavigator(toc);
      expect(toc.items, isNotEmpty);

      // Check that we have GroupItems for top-level sections
      final sections = toc.items.whereType<GroupItem>().toList();
      expect(sections, isNotEmpty);

      // The first section should be "פרשת בראשית" (Parshat Bereshit)
      expect(sections[0].title, contains('בראשית'));

      // It should have subsections as children
      expect(sections[0].children, isNotEmpty);

      // Children should be ContentItems for subsections
      final subsections =
          sections[0].children.whereType<ContentItem>().toList();
      expect(subsections, isNotEmpty);

      // First subsection should be "פרק-א" (Chapter 1)
      expect(subsections[0].title, contains('פרק'));
    });

    test('extracts correct number of sections from Genesis', () async {
      final file = File(p.join(samplesDir, 'f_00760.html'));
      final content = await file.readAsString();
      final document = html_parser.parse(content);
      final bookNav = BookContentNavigation(document);
      final toc = bookNav.extractTableOfContents();

      final sections = toc.items.whereType<GroupItem>().toList();

      // Genesis (Bereshit) has 12 parshiot (weekly Torah portions)
      expect(sections.length, equals(12));
    });

    test('sections have correct subsection structure', () async {
      final file = File(p.join(samplesDir, 'f_00760.html'));
      final content = await file.readAsString();
      final document = html_parser.parse(content);
      final bookNav = BookContentNavigation(document);
      final toc = bookNav.extractTableOfContents();

      final sections = toc.items.whereType<GroupItem>().toList();

      // First section (Bereshit) should have 6 chapters
      expect(sections[0].children.length, equals(6));

      // Second section (Noach) should have 5 chapters
      expect(sections[1].children.length, equals(5));

      // Third section (Lech Lecha) should have 6 chapters
      expect(sections[2].children.length, equals(6));
    });

    test('subsections have correct anchor format', () async {
      final file = File(p.join(samplesDir, 'f_00760.html'));
      final content = await file.readAsString();
      final document = html_parser.parse(content);
      final bookNav = BookContentNavigation(document);
      final toc = bookNav.extractTableOfContents();

      final sections = toc.items.whereType<GroupItem>().toList();
      final firstSection = sections[0];
      final firstSubsection = firstSection.children.first as ContentItem;

      // Check that the anchor is in the correct format (L2 for subsections)
      expect(firstSubsection.section.anchor, contains('HtmpReportNum'));
      expect(firstSubsection.section.anchor, contains('_L2'));
    });

    test('handles empty or invalid files gracefully', () async {
      final tempDir = await Directory.systemTemp.createTemp('content_test_');

      try {
        final file = File(p.join(tempDir.path, 'empty.html'));
        await file.writeAsString('<html><body></body></html>');

        final content = await file.readAsString();
        final document = html_parser.parse(content);
        final bookNav = BookContentNavigation(document);
        final toc = bookNav.extractTableOfContents();

        // Should return empty TOC for files without the expected structure
        expect(toc.items, isEmpty);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('throws FileSystemException for non-existent file', () async {
      final file = File('/nonexistent/file.html');
      expect(
        () async => await file.readAsString(),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('TableOfContentsItem hierarchy', () {
    test('GroupItem contains ContentItem children', () {
      final contentItem = ContentItem(
        title: 'Chapter 1',
        section: ContentSection(
          title: 'Chapter 1',
          anchor: 'chapter1',
        ),
      );

      final groupItem = GroupItem(
        title: 'Parsha',
        children: [contentItem],
      );

      expect(groupItem.children, hasLength(1));
      expect(groupItem.children.first, isA<ContentItem>());
      expect(groupItem.children.first.title, equals('Chapter 1'));
    });

    test('nested GroupItems are possible', () {
      final leaf = ContentItem(
        title: 'Section',
        section: ContentSection(
          title: 'Section',
          anchor: 'section',
        ),
      );

      final subGroup = GroupItem(title: 'SubGroup', children: [leaf]);
      final topGroup = GroupItem(title: 'TopGroup', children: [subGroup]);

      expect(topGroup.children.first, isA<GroupItem>());
      final sub = topGroup.children.first as GroupItem;
      expect(sub.children.first, isA<ContentItem>());
    });
  });
}
