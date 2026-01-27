import 'dart:io';
import '../phase_1_navigation/book_reference.dart';
import '../phase_1_navigation/file_system.dart';

/// Creates and manages output folder structure.
/// Organizes books into nested folders based on breadcrumbs.
class BookFolderOrganizer {
  final FileSystem fileSystem;

  BookFolderOrganizer(this.fileSystem);

  /// Create the output folder structure for a book.
  /// Returns the created Directory for use in subsequent writes.
  /// Example: output/תורה/בראשית/בראשית/
  Future<Directory> createBookFolder(String outputRoot, BookReference book) async {
    final pathParts = [outputRoot, ...book.breadcrumbs, book.title];
    final folderPath = pathParts.join(Platform.pathSeparator);

    // Create directories
    final dir = Directory(folderPath);
    await dir.create(recursive: true);

    return dir;
  }

  /// Sanitize a folder name for filesystem compatibility.
  String sanitizeFolderName(String name) {
    // Remove characters that are problematic on most filesystems
    return name
        .replaceAll(RegExp(r'[<>:"|?*]'), '')
        .replaceAll(RegExp(r'[\x00-\x1f]'), '')
        .trim();
  }
}
