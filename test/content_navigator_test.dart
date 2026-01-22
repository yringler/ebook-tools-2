import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../lib/content_navigator.dart';

void main() {
  group('ContentNavigator', () {
    final samplesDir = p.join(Directory.current.path, 'samples');

    test('parses f_00760.html nested Bible TOC structure', () async {
      final navigator = await ContentNavigator.parse(
        p.join(samplesDir, 'f_00760.html'),
      );

      final toc = navigator.tableOfContents;
      expect(toc.items, isNotEmpty);

      // Check that we have GroupItems for parshiot
      final parshiot = toc.items.whereType<GroupItem>().toList();
      expect(parshiot, isNotEmpty);

      // The first item should be "פרשת בראשית" (Parshat Bereshit)
      expect(parshiot[0].title, contains('בראשית'));

      // It should have chapters as children
      expect(parshiot[0].children, isNotEmpty);

      // Children should be ContentItems for chapters
      final chapters = parshiot[0].children.whereType<ContentItem>().toList();
      expect(chapters, isNotEmpty);

      // First chapter should be "פרק-א" (Chapter 1)
      expect(chapters[0].title, contains('פרק'));
    });

    test('extracts correct number of parshiot from Genesis', () async {
      final navigator = await ContentNavigator.parse(
        p.join(samplesDir, 'f_00760.html'),
      );

      final parshiot = navigator.tableOfContents.items.whereType<GroupItem>().toList();

      // Genesis (Bereshit) has 12 parshiot
      expect(parshiot.length, equals(12));
    });

    test('parshiot have correct chapter structure', () async {
      final navigator = await ContentNavigator.parse(
        p.join(samplesDir, 'f_00760.html'),
      );

      final parshiot = navigator.tableOfContents.items.whereType<GroupItem>().toList();

      // First parsha (Bereshit) should have 6 chapters
      expect(parshiot[0].children.length, equals(6));

      // Second parsha (Noach) should have 5 chapters
      expect(parshiot[1].children.length, equals(5));

      // Third parsha (Lech Lecha) should have 6 chapters
      expect(parshiot[2].children.length, equals(6));
    });

    test('chapters have correct anchors', () async {
      final navigator = await ContentNavigator.parse(
        p.join(samplesDir, 'f_00760.html'),
      );

      final parshiot = navigator.tableOfContents.items.whereType<GroupItem>().toList();
      final firstParsha = parshiot[0];
      final firstChapter = firstParsha.children.first as ContentItem;

      // Check that the anchor is in the correct format
      expect(firstChapter.section.anchor, contains('HtmpReportNum'));
      expect(firstChapter.section.anchor, contains('_L2'));
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
