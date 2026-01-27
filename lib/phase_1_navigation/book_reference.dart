import '../table_of_contents.dart';

/// Reference to a discovered book with metadata and location.
class BookReference {
  final String title;
  final String filePath;
  final IndexItemType type;
  final List<String> breadcrumbs; // e.g., ["תורה", "בראשית"]

  BookReference({
    required this.title,
    required this.filePath,
    required this.type,
    required this.breadcrumbs,
  });
}
