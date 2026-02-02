import 'dart:io';
import 'package:ebook_html_converter/phase_1_navigation/real_file_system.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('RealFileSystem', () {
    late Directory tempDir;
    late RealFileSystem fileSystem;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_system_test_');
      fileSystem = RealFileSystem();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('readFile', () {
      test('reads existing file content', () async {
        final testFile = File(p.join(tempDir.path, 'test.txt'));
        await testFile.writeAsString('Hello, World!');

        final content = await fileSystem.readFile(testFile.path);

        expect(content, equals('Hello, World!'));
      });

      test('reads UTF-8 encoded content', () async {
        final testFile = File(p.join(tempDir.path, 'hebrew.txt'));
        await testFile.writeAsString('שלום עולם');

        final content = await fileSystem.readFile(testFile.path);

        expect(content, equals('שלום עולם'));
      });

      test('reads multiline content', () async {
        final testFile = File(p.join(tempDir.path, 'multiline.txt'));
        await testFile.writeAsString('Line 1\nLine 2\nLine 3');

        final content = await fileSystem.readFile(testFile.path);

        expect(content, equals('Line 1\nLine 2\nLine 3'));
      });

      test('throws FileSystemException for non-existent file', () async {
        final nonExistentPath = p.join(tempDir.path, 'nonexistent.txt');

        expect(
          () => fileSystem.readFile(nonExistentPath),
          throwsA(isA<FileSystemException>()),
        );
      });
    });

    group('fileExists', () {
      test('returns true for existing file', () async {
        final testFile = File(p.join(tempDir.path, 'exists.txt'));
        await testFile.writeAsString('content');

        final exists = await fileSystem.fileExists(testFile.path);

        expect(exists, isTrue);
      });

      test('returns false for non-existent file', () async {
        final nonExistentPath = p.join(tempDir.path, 'nonexistent.txt');

        final exists = await fileSystem.fileExists(nonExistentPath);

        expect(exists, isFalse);
      });

      test('returns false for directory', () async {
        final subDir = Directory(p.join(tempDir.path, 'subdir'));
        await subDir.create();

        final exists = await fileSystem.fileExists(subDir.path);

        expect(exists, isFalse);
      });
    });

    group('resolvePath', () {
      test('resolves relative path from base file path', () {
        final basePath = p.join(tempDir.path, 'folder', 'base.html');
        final relativePath = 'relative.html';

        final resolved = fileSystem.resolvePath(basePath, relativePath);

        expect(resolved, equals(p.join(tempDir.path, 'folder', 'relative.html')));
      });

      test('resolves path with parent directory reference', () {
        final basePath = p.join(tempDir.path, 'folder', 'subfolder', 'base.html');
        final relativePath = '../other.html';

        final resolved = fileSystem.resolvePath(basePath, relativePath);

        // Should resolve to tempDir/folder/subfolder/../other.html
        // which normalizes to tempDir/folder/other.html
        expect(resolved, contains('other.html'));
        expect(resolved, contains(p.join('folder', 'subfolder')));
      });

      test('resolves nested relative path', () {
        final basePath = p.join(tempDir.path, 'base.html');
        final relativePath = p.join('nested', 'path', 'file.html');

        final resolved = fileSystem.resolvePath(basePath, relativePath);

        expect(resolved, endsWith(p.join('nested', 'path', 'file.html')));
      });

      test('uses platform-specific path separator', () {
        final basePath = p.join(tempDir.path, 'base.html');
        final relativePath = 'file.html';

        final resolved = fileSystem.resolvePath(basePath, relativePath);

        expect(resolved, contains(Platform.pathSeparator));
      });
    });

    group('integration', () {
      test('can read file at resolved path', () async {
        // Create directory structure
        final subDir = Directory(p.join(tempDir.path, 'subdir'));
        await subDir.create();

        // Create files
        final baseFile = File(p.join(tempDir.path, 'base.html'));
        await baseFile.writeAsString('base content');

        final targetFile = File(p.join(subDir.path, 'target.html'));
        await targetFile.writeAsString('target content');

        // Resolve path
        final resolved = fileSystem.resolvePath(
          baseFile.path,
          p.join('subdir', 'target.html'),
        );

        // Verify file exists and can be read
        expect(await fileSystem.fileExists(resolved), isTrue);
        final content = await fileSystem.readFile(resolved);
        expect(content, equals('target content'));
      });
    });
  });
}
