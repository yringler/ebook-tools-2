import 'book_reference.dart';
import 'index_file_reader.dart';
import 'path_resolver.dart';
import '../table_of_contents.dart';

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
        final folderPath = pathResolver.resolve(currentDir, item.href);
        final newBreadcrumbs = [...breadcrumbs, item.title];

        final folderIndex = await indexReader.readIndex(folderPath);
        await _navigateItems(folderIndex.items, folderPath, newBreadcrumbs, books);
      } else if (item.type == IndexItemType.book) {
        // Add book reference
        final bookPath = pathResolver.resolve(currentDir, item.href);
        books.add(BookReference(
          title: item.title,
          filePath: bookPath,
          type: item.type,
          breadcrumbs: breadcrumbs,
        ));
      }
    }
  }
}
