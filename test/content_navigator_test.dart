import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../lib/content_navigator.dart';

void main() {
  group('ContentNavigator', () {
    final samplesDir = p.join(Directory.current.path, 'samples');

    test('parses nested TOC structure with sections and subsections', () async {
      // f_00760.html is a Bible text (Genesis) with parshiot > chapters structure
      final navigator = await ContentNavigator.parse(
        p.join(samplesDir, 'f_00760.html'),
      );

      final toc = navigator.tableOfContents;
      expect(toc.items, isNotEmpty);

      // Check that we have GroupItems for top-level sections
      final sections = toc.items.whereType<GroupItem>().toList();
      expect(sections, isNotEmpty);

      // The first section should be "פרשת בראשית" (Parshat Bereshit)
      expect(sections[0].title, contains('בראשית'));

      // It should have subsections as children
      expect(sections[0].children, isNotEmpty);

      // Children should be ContentItems for subsections
      final subsections = sections[0].children.whereType<ContentItem>().toList();
      expect(subsections, isNotEmpty);

      // First subsection should be "פרק-א" (Chapter 1)
      expect(subsections[0].title, contains('פרק'));
    });

    test('extracts correct number of sections from Genesis', () async {
      final navigator = await ContentNavigator.parse(
        p.join(samplesDir, 'f_00760.html'),
      );

      final sections = navigator.tableOfContents.items.whereType<GroupItem>().toList();

      // Genesis (Bereshit) has 12 parshiot (weekly Torah portions)
      expect(sections.length, equals(12));
    });

    test('sections have correct subsection structure', () async {
      final navigator = await ContentNavigator.parse(
        p.join(samplesDir, 'f_00760.html'),
      );

      final sections = navigator.tableOfContents.items.whereType<GroupItem>().toList();

      // First section (Bereshit) should have 6 chapters
      expect(sections[0].children.length, equals(6));

      // Second section (Noach) should have 5 chapters
      expect(sections[1].children.length, equals(5));

      // Third section (Lech Lecha) should have 6 chapters
      expect(sections[2].children.length, equals(6));
    });

    test('subsections have correct anchor format', () async {
      final navigator = await ContentNavigator.parse(
        p.join(samplesDir, 'f_00760.html'),
      );

      final sections = navigator.tableOfContents.items.whereType<GroupItem>().toList();
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

        final navigator = await ContentNavigator.parse(file.path);

        // Should return empty TOC for files without the expected structure
        expect(navigator.tableOfContents.items, isEmpty);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('throws FileSystemException for non-existent file', () async {
      expect(
        () => ContentNavigator.parse('/nonexistent/file.html'),
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
          content: DocumentFragment(),
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
          content: DocumentFragment(),
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
