# Ebook HTML Converter - Architecture Plan

## Overview
Process a hierarchical HTML library into individual ebook-ready folders. Each book gets its own folder with a clean TOC (index.html) and split section files for Calibre conversion.

## Design Principles
- **Single Responsibility Principle**: Each class has one clear purpose
- **Testability**: Dependencies are injected and mockable
- **Parallel Development**: Classes are independent enough for multiple agents to work simultaneously
- **Dependency Injection**: Dependencies (services/interfaces needed to do the job) are passed via constructor. Materials (data being operated on) are passed as method arguments.

## Class Structure

### 1. Navigation & Discovery Layer

#### `FileSystem` (Interface)
**Purpose**: Abstract file system operations for testing  
**Responsibilities**:
- Read file contents
- Check file existence
- Resolve relative paths

**Methods**:
```dart
Future<String> readFile(String path);
Future<bool> fileExists(String path);
String resolvePath(String base, String relative);
```

#### `RealFileSystem`
**Purpose**: Production implementation of FileSystem  
**Dependencies**: `dart:io`

#### `LibraryIndexParser` (EXISTS)
**Purpose**: Parse index/folder HTML pages to extract navigation items  
**Input**: `Document` (from html package)  
**Output**: `Index` containing list of `IndexItem`  
**Location**: `lib/library_index_parser.dart`

#### `IndexFileReader`
**Purpose**: Load and parse an index HTML file
**Dependencies**: `FileSystem` (constructor), `LibraryIndexParser` (constructor)
**Responsibilities**:
- Load HTML file from disk
- Parse with html package to create Document
- Pass Document to LibraryIndexParser
- Return parsed Index

**Constructor**:
```dart
IndexFileReader(this.fileSystem, this.parser);
```

**Methods**:
```dart
Future<Index> readIndex(String filePath);
```

#### `PathResolver`
**Purpose**: Build absolute file paths from relative references  
**Note**: Thin wrapper around `path` package for consistent path resolution  
**Dependencies**: `FileSystem` (constructor)  
**Responsibilities**:
- Resolve relative paths from current file location (wraps `path.join(path.dirname(base), relative)`)
- Normalize path separators
- Validate path existence (via FileSystem)

**Constructor**:
```dart
PathResolver(this.fileSystem);
```

**Methods**:
```dart
String resolve(String basePath, String relativePath);
Future<String> validateAndResolve(String basePath, String relativePath);
```

#### `HierarchyNavigator`
**Purpose**: Walk through folder→folder→book hierarchy  
**Dependencies**: `IndexFileReader` (constructor), `PathResolver` (constructor)  
**Responsibilities**:
- Start from root index
- Recursively follow folder links
- Identify book files (type already in IndexItem from AddIndex calls)
- Build list of all books in library with breadcrumbs

**Constructor**:
```dart
HierarchyNavigator(this.indexReader, this.pathResolver);
```

**Methods**:
```dart
Future<List<BookReference>> discoverBooks(String rootPath);
```

**Output Model**:
```dart
class BookReference {
  final String title;
  final String filePath;
  final IndexItemType type;
  final List<String> breadcrumbs; // e.g., ["תורה", "בראשית"]
}
```

### 2. Table of Contents Layer

#### BookTableOfContentsParser (EXISTS)
**Purpose**: Extract hierarchical TOC from book HTML
**Input**: `Document`
**Output**: `TableOfContents`
**Location**: `lib/book_table_of_contents_parser.dart`
**Note**: Already implements parsing of L99/L2 anchor patterns

#### TocHtmlGenerator
**Purpose**: Create clean index.html with TOC for Calibre
**Dependencies**: `SectionFileMapper` (constructor)
**Responsibilities**:
- Generate clean HTML structure
- Create links to section files (using SectionFileMapper)
- Apply minimal, ebook-friendly styling

**Constructor**:
```dart
TocHtmlGenerator(this.fileMapper);
```

**Methods**:
```dart
String generate(TableOfContents toc, BookReference book);
```

#### ContentSectionExtractor
**Purpose**: Extract HTML content between specific anchors
**Dependencies**: None (stateless utility)
**Responsibilities**:
- Find content between L2/L5/L99 anchors
- Extract complete HTML elements
- Preserve internal structure

**Methods**:
```dart
Element? extractSection(Document doc, String anchorName);
Element? extractSectionRange(Document doc, String startAnchor, String endAnchor);
```

#### SectionFileMapper
**Purpose**: Map TOC sections to output filenames
**Dependencies**: None (stateless utility)
**Responsibilities**:
- Generate unique filenames from ContentItem sections
- Use anchor names or sanitized titles for filenames
- Provide consistent mapping for both splitting and TOC generation

**Methods**:
```dart
String getFilenameForSection(ContentItem item);
Map<ContentItem, String> mapAllSections(TableOfContents toc);
```

**Example**:
```dart
// Uses anchor: "HtmpReportNum0000_L2.html"
// OR sanitized title: "perek_aleph.html"
```

### 3. Content Processing Layer

#### SectionSplitter
**Purpose**: Split book HTML into separate files per section
**Dependencies**: `ContentSectionExtractor` (constructor), `SectionFileMapper` (constructor)
**Responsibilities**:
- Create one Element per chapter/section
- Use SectionFileMapper for consistent filenames
- Coordinate section extraction

**Constructor**:
```dart
SectionSplitter(this.extractor, this.fileMapper);
```

**Methods**:
```dart
Map<String, Element> splitIntoSections(Document doc, TableOfContents toc);
```

**Output**: Map of filename → HTML Element

#### HtmlCleaner
**Purpose**: Remove unwanted elements from HTML
**Dependencies**: None (stateless utility)
**Responsibilities**:
- Remove `<script>` tags
- Remove navigation elements
- Strip unnecessary attributes
- Keep content and basic formatting

**Methods**:
```dart
Document clean(Document doc);
Element cleanElement(Element element);
```

#### StyleNormalizer
**Purpose**: Standardize inline styles for Calibre compatibility
**Dependencies**: None (stateless utility)
**Responsibilities**:
- Convert inline styles to consistent format
- Remove unsupported CSS
- Preserve essential formatting (bold, colors, sizes)

**Methods**:
```dart
Document normalize(Document doc);
String normalizeStyleAttribute(String style);
```

#### AnchorRewriter
**Purpose**: Update anchor hrefs when splitting into multiple files
**Dependencies**: `SectionFileMapper` (constructor)
**Responsibilities**:
- Rewrite internal `href="#anchor"` to `file.html#anchor`
- Update TOC links to point to correct files
- Preserve external links

**Constructor**:
```dart
AnchorRewriter(this.fileMapper);
```

**Methods**:
```dart
Document rewriteAnchors(Document doc, TableOfContents toc);
```

### 4. Output Layer

#### BookFolderOrganizer
**Purpose**: Create and manage output folder structure
**Dependencies**: `FileSystem` (constructor)
**Responsibilities**:
- Create nested folder structure from breadcrumbs (e.g., output/תורה/בראשית/בראשית/)
- Handle path collisions
- Sanitize folder names for filesystem compatibility

**Constructor**:
```dart
BookFolderOrganizer(this.fileSystem);
```

**Methods**:
```dart
Future<Directory> createBookFolder(String outputRoot, BookReference book);
```
- Returns the created Directory for use in subsequent file writes

**Example Output Structure**:
```
output/
  תורה/
    בראשית/
      בראשית/
        index.html
        section1.html
      בראשית - רש''י/
        index.html
        section1.html
```

#### FileWriter
**Purpose**: Write processed HTML files to disk
**Dependencies**: `FileSystem` (constructor)
**Responsibilities**:
- Write HTML documents to files
- Ensure proper encoding (UTF-8 for output)
- Create parent directories as needed

**Constructor**:
```dart
FileWriter(this.fileSystem);
```

**Methods**:
```dart
Future<void> writeHtml(String path, Document doc);
Future<void> writeString(String path, String content);
```

### 5. Orchestration

#### BookProcessor
**Purpose**: Coordinate the complete workflow for a single book
**Dependencies**:
- `FileSystem` (constructor)
- `BookTableOfContentsParser` (constructor)
- `SectionSplitter` (constructor)
- `HtmlCleaner` (constructor)
- `StyleNormalizer` (constructor)
- `AnchorRewriter` (constructor)
- `BookFolderOrganizer` (constructor)
- `TocHtmlGenerator` (constructor)
- `FileWriter` (constructor)

**Responsibilities**:
- Load book HTML
- Extract TOC
- Split into sections
- Clean and normalize HTML
- Generate output files

**Constructor**:
```dart
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
```

**Methods**:
```dart
Future<void> processBook(BookReference book, String outputRoot);
```

**Workflow**:
1. Load HTML (via FileSystem)
2. Parse with html library → Document
3. Extract TOC (BookTableOfContentsParser)
4. Split into sections (SectionSplitter)
5. Clean HTML (HtmlCleaner)
6. Normalize styles (StyleNormalizer)
7. Rewrite anchors (AnchorRewriter)
8. Create output folder (BookFolderOrganizer)
9. Generate TOC HTML (TocHtmlGenerator)
10. Write files (FileWriter)

#### LibraryProcessor
**Purpose**: Process entire library hierarchy
**Dependencies**: `HierarchyNavigator` (constructor), `BookProcessor` (constructor)
**Responsibilities**:
- Discover all books in library
- Process each book
- Handle errors gracefully
- Report progress

**Constructor**:
```dart
LibraryProcessor(this.navigator, this.bookProcessor);
```

**Methods**:
```dart
Future<void> processLibrary(String rootPath, String outputRoot);
```

## Existing Code

### Already Implemented
- `LibraryIndexParser` - Parses AddIndex() calls from HTML
- `BookTableOfContentsParser` - Extracts TOC structure (L99/L2 anchors)
- `TableOfContents` - Models for TOC structure (GroupItem, ContentItem, ContentSection)
- `ContentNavigator` - Stub, needs implementation
- `HtmlConverter` - Minimal, can be replaced/expanded

### Models in Place
- `IndexItem`, `Index`, `IndexItemType`
- `ContentSection`, `TableOfContentsItem`, `ContentItem`, `GroupItem`, `TableOfContents`

## Development Strategy

### Phase 1: Navigation & Discovery
1. FileSystem interface + RealFileSystem
2. PathResolver
3. IndexFileReader
4. HierarchyNavigator

**Output**: Can discover all books in library with metadata (title, type, breadcrumbs)

### Phase 2: Content Extraction
5. SectionFileMapper
6. ContentSectionExtractor
7. SectionSplitter

**Output**: Can split a book into section pieces

### Phase 3: Content Processing
8. HtmlCleaner
9. StyleNormalizer
10. AnchorRewriter

**Output**: Clean, normalized HTML ready for Calibre

### Phase 4: Output Generation
11. TocHtmlGenerator
12. BookFolderOrganizer
13. FileWriter

**Output**: Can write processed books to disk

### Phase 5: Orchestration
14. BookProcessor
15. LibraryProcessor
16. Update main CLI to use new architecture

**Output**: Complete working system

## Parallel Development Approach

Each class is independent enough for different agents to work on simultaneously:
- **Agent 1**: Phase 1 (Navigation)
- **Agent 2**: Phase 2 (Extraction)
- **Agent 3**: Phase 3 (Processing)
- **Agent 4**: Phase 4 (Output)
- **Agent 5**: Tests for Phase 1
- **Agent 6**: Tests for Phase 2-3

Classes communicate through well-defined interfaces and models, minimizing conflicts.
