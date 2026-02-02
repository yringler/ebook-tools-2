import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:ebook_html_converter/phase_1_navigation/path_resolver.dart';
import 'package:ebook_html_converter/phase_1_navigation/file_system.dart';

class MockFileSystem implements FileSystem {
  final Set<String> existingFiles;

  MockFileSystem(this.existingFiles);

  @override
  Future<bool> fileExists(String path) async {
    return existingFiles.contains(path);
  }

  @override
  Future<String> readFile(String path) async {
    throw UnimplementedError();
  }

  @override
  String resolvePath(String base, String relative) {
    throw UnimplementedError();
  }
}

void main() {
  group('PathResolver.resolve', () {
    late PathResolver resolver;

    setUp(() {
      resolver = PathResolver(MockFileSystem({}));
    });

    test('resolves relative path from base directory', () {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final result = resolver.resolve(basePath, 'other.html');
      final expected =
          p.normalize(p.join(p.separator, 'base', 'dir', 'other.html'));
      expect(result, equals(expected));
    });

    test('resolves parent directory reference', () {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final result = resolver.resolve(basePath, p.join('..', 'other.html'));
      final expected = p.normalize(p.join(p.separator, 'base', 'other.html'));
      expect(result, equals(expected));
    });

    test('resolves nested relative path', () {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final result = resolver.resolve(basePath, p.join('sub', 'other.html'));
      final expected =
          p.normalize(p.join(p.separator, 'base', 'dir', 'sub', 'other.html'));
      expect(result, equals(expected));
    });

    test('resolves multiple parent references', () {
      final basePath = p.join(p.separator, 'base', 'dir', 'sub', 'file.html');
      final result =
          resolver.resolve(basePath, p.join('..', '..', 'other.html'));
      final expected = p.normalize(p.join(p.separator, 'base', 'other.html'));
      expect(result, equals(expected));
    });

    test('normalizes redundant path separators', () {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final result =
          resolver.resolve(basePath, p.join('.', 'sub', '.', 'other.html'));
      final expected =
          p.normalize(p.join(p.separator, 'base', 'dir', 'sub', 'other.html'));
      expect(result, equals(expected));
    });

    test('handles Windows-style paths on Windows', () {
      final result = resolver.resolve('C:\\base\\dir\\file.html', 'other.html');
      expect(result, equals('C:\\base\\dir\\other.html'));
    });

    test('handles mixed path separators', () {
      final result =
          resolver.resolve('C:\\base\\dir\\file.html', '../other.html');
      expect(result, equals('C:\\base\\other.html'));
    });
  });

  group('PathResolver.validateAndResolve', () {
    test('returns resolved path when file exists', () async {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final expected =
          p.normalize(p.join(p.separator, 'base', 'dir', 'other.html'));
      final mockFS = MockFileSystem({expected});
      final resolver = PathResolver(mockFS);

      final result = await resolver.validateAndResolve(basePath, 'other.html');
      expect(result, equals(expected));
    });

    test('throws FileNotFoundException when file does not exist', () async {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final mockFS = MockFileSystem({});
      final resolver = PathResolver(mockFS);

      expect(
        () => resolver.validateAndResolve(basePath, 'other.html'),
        throwsA(isA<FileNotFoundException>()),
      );
    });

    test('throws FileNotFoundException with correct path in message', () async {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final expected =
          p.normalize(p.join(p.separator, 'base', 'dir', 'other.html'));
      final mockFS = MockFileSystem({});
      final resolver = PathResolver(mockFS);

      try {
        await resolver.validateAndResolve(basePath, 'other.html');
        fail('Expected FileNotFoundException');
      } on FileNotFoundException catch (e) {
        expect(e.message, contains(expected));
      }
    });

    test('validates resolved path with parent directory', () async {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final expected = p.normalize(p.join(p.separator, 'base', 'other.html'));
      final mockFS = MockFileSystem({expected});
      final resolver = PathResolver(mockFS);

      final result = await resolver.validateAndResolve(
          basePath, p.join('..', 'other.html'));
      expect(result, equals(expected));
    });

    test('validates resolved path with nested directory', () async {
      final basePath = p.join(p.separator, 'base', 'dir', 'file.html');
      final expected =
          p.normalize(p.join(p.separator, 'base', 'dir', 'sub', 'other.html'));
      final mockFS = MockFileSystem({expected});
      final resolver = PathResolver(mockFS);

      final result = await resolver.validateAndResolve(
          basePath, p.join('sub', 'other.html'));
      expect(result, equals(expected));
    });
  });

  group('FileNotFoundException', () {
    test('toString returns the message', () {
      final exception = FileNotFoundException('Test error message');
      expect(exception.toString(), equals('Test error message'));
    });

    test('message is accessible', () {
      final exception = FileNotFoundException('Custom message');
      expect(exception.message, equals('Custom message'));
    });
  });
}
