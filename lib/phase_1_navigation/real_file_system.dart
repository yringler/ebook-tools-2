import 'dart:io';
import 'file_system.dart';

/// Production implementation of FileSystem using dart:io.
class RealFileSystem implements FileSystem {
  @override
  Future<String> readFile(String path) async {
    return File(path).readAsString();
  }

  @override
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  @override
  String resolvePath(String base, String relative) {
    return File(base).parent.path + Platform.pathSeparator + relative;
  }
}
