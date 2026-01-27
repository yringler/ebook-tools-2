import '../phase_1_navigation/hierarchy_navigator.dart';
import 'book_processor.dart';

/// Processes entire library hierarchy.
/// Discovers all books and coordinates batch processing.
class LibraryProcessor {
  final HierarchyNavigator navigator;
  final BookProcessor bookProcessor;

  LibraryProcessor(this.navigator, this.bookProcessor);

  /// Process all books in the library.
  /// Discovers books and processes each one with progress reporting.
  Future<void> processLibrary(String rootPath, String outputRoot) async {
    try {
      // Discover all books
      final books = await navigator.discoverBooks(rootPath);
      print('Discovered ${books.length} books');

      // Process each book
      int processed = 0;
      for (final book in books) {
        try {
          print('Processing: ${book.title}');
          await bookProcessor.processBook(book, outputRoot);
          processed++;
        } catch (e) {
          print('Error processing ${book.title}: $e');
          // Continue with next book on error
        }
      }

      print('Completed: $processed/${books.length} books processed successfully');
    } catch (e) {
      print('Error discovering books: $e');
      rethrow;
    }
  }
}
