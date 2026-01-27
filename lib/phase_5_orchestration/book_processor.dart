import 'package:html/parser.dart' as html_parser;
import '../book_table_of_contents_parser.dart';
import '../phase_1_navigation/book_reference.dart';
import '../phase_1_navigation/file_system.dart';
import '../phase_2_extraction/section_file_mapper.dart';
import '../phase_2_extraction/section_splitter.dart';
import '../phase_3_processing/anchor_rewriter.dart';
import '../phase_3_processing/html_cleaner.dart';
import '../phase_3_processing/style_normalizer.dart';
import '../phase_4_output/book_folder_organizer.dart';
import '../phase_4_output/file_writer.dart';
import '../phase_4_output/toc_html_generator.dart';

/// Coordinates the complete workflow for processing a single book.
/// Orchestrates all phases: extraction, processing, and output.
class BookProcessor {
  final FileSystem fileSystem;
  final BookTableOfContentsParser tocParser;
  final SectionSplitter splitter;
  final HtmlCleaner cleaner;
  final StyleNormalizer styleNormalizer;
  final AnchorRewriter anchorRewriter;
  final BookFolderOrganizer folderOrganizer;
  final TocHtmlGenerator tocGenerator;
  final FileWriter fileWriter;

  BookProcessor(
    this.fileSystem,
    this.tocParser,
    this.splitter,
    this.cleaner,
    this.styleNormalizer,
    this.anchorRewriter,
    this.folderOrganizer,
    this.tocGenerator,
    this.fileWriter,
  );

  /// Process a book through the entire pipeline.
  /// Coordinates loading, parsing, splitting, cleaning, and writing.
  Future<void> processBook(BookReference book, String outputRoot) async {
    // 1. Load HTML
    final htmlContent = await fileSystem.readFile(book.filePath);
    var document = html_parser.parse(htmlContent);

    // 2. Extract TOC
    final toc = tocParser.parse(document);

    // 3. Split into sections
    final sections = splitter.splitIntoSections(document, toc);

    // 4. Clean HTML
    document = cleaner.clean(document);

    // 5. Normalize styles
    document = styleNormalizer.normalize(document);

    // 6. Rewrite anchors
    document = anchorRewriter.rewriteAnchors(document, toc);

    // 7. Create output folder
    final bookFolder = await folderOrganizer.createBookFolder(outputRoot, book);

    // 8. Generate TOC HTML
    final tocHtml = tocGenerator.generate(toc, book);

    // 9. Write files
    await fileWriter.writeString('${bookFolder.path}/index.html', tocHtml);

    for (final entry in sections.entries) {
      final filename = entry.key;
      final element = entry.value;
      final filePath = '${bookFolder.path}/$filename';
      await fileWriter.writeHtml(filePath, element);
    }
  }
}
