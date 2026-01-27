/// Abstract interface for file system operations.
/// Enables testing by allowing mock implementations.
abstract class FileSystem {
  /// Read the contents of a file as a String.
  Future<String> readFile(String path);

  /// Check if a file exists at the given path.
  Future<bool> fileExists(String path);

  /// Resolve a relative path from a base path.
  String resolvePath(String base, String relative);
}
