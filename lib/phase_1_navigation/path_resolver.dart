import 'package:path/path.dart' as path;
import 'file_system.dart';

/// Builds absolute file paths from relative references.
/// Thin wrapper around the path package for consistent resolution.
class PathResolver {
  final FileSystem fileSystem;

  PathResolver(this.fileSystem);

  /// Resolve a relative path from a base path.
  /// Wraps path.join(path.dirname(base), relative).
  String resolve(String basePath, String relativePath) {
    final baseDir = path.dirname(basePath);
    return path.normalize(path.join(baseDir, relativePath));
  }

  /// Validate that the resolved path exists and return it.
  Future<String> validateAndResolve(String basePath, String relativePath) async {
    final resolved = resolve(basePath, relativePath);
    final exists = await fileSystem.fileExists(resolved);
    if (!exists) {
      throw FileNotFoundException('Path does not exist: $resolved');
    }
    return resolved;
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);

  @override
  String toString() => message;
}
