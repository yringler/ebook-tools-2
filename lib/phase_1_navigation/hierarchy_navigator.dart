import 'package:ebook_html_converter/phase_1_navigation/library_index_parser.dart';

import 'book_reference.dart';
import 'index_file_reader.dart';
import 'path_resolver.dart';

/// Walks through the folder→folder→book hierarchy to discover all books.
/// Recursively follows folder links and builds a list of all books with breadcrumbs.
class HierarchyNavigator {
  final IndexFileReader indexReader;
  final PathResolver pathResolver;

  HierarchyNavigator(this.indexReader, this.pathResolver);

  /// Discover all books in the library starting from the root index.
  /// Returns a list of BookReference objects with full metadata.
  Future<List<BookReference>> discoverBooks(String rootPath) async {
    final books = <BookReference>[];
    final index = await indexReader.readIndex(rootPath);

    await _navigateItems(index.items, rootPath, [], books);

    return books;
  }

  Future<void> _navigateItems(
    List<IndexItem> items,
    String currentDir,
    List<String> breadcrumbs,
    List<BookReference> books,
  ) async {
    for (final item in items) {
      if (item.type == IndexItemType.folder) {
        // Recursively navigate folder
        final folderPath = pathResolver.resolve(currentDir, item.path);
        final newBreadcrumbs = [...breadcrumbs, item.name];

        final folderIndex = await indexReader.readIndex(folderPath);
        await _navigateItems(
            folderIndex.items, folderPath, newBreadcrumbs, books);
      } else if (item.type == IndexItemType.book) {
        // Add book reference
        final bookPath = pathResolver.resolve(currentDir, item.path);
        books.add(BookReference(
          title: item.name,
          filePath: bookPath,
          type: item.type,
          breadcrumbs: breadcrumbs,
        ));
      }
    }
  }
}
