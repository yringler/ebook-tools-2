# Claude Code Configuration for Ebook Tools

## Project Overview
This is a Dart/Flutter project that converts hierarchical HTML libraries into ebook-ready folders for Calibre conversion. The project follows a clean architecture with dependency injection and single responsibility principles.

## Key Architecture Points
- **Phase-based organization**: Code is organized into 5 phases (navigation, extraction, processing, output, orchestration)
- **Dependency Injection**: Dependencies are passed via constructors, materials are passed as method arguments
- **Immutable Models**: `ContentSection`, `ContentItem`, `GroupItem`, `TableOfContents`, `BookReference`, `IndexItem`
- **Stub-based Development**: Most classes are stubs; only core parsers are fully implemented

## Important Model Structure

### Table of Contents Hierarchy
```dart
TableOfContents
  └─ items: List<TableOfContentsItem>  // sealed class
      ├─ ContentItem (leaf)
      │   ├─ title: String
      │   └─ section: ContentSection
      │       ├─ title: String
      │       └─ anchor: String
      └─ GroupItem (parent)
          ├─ title: String
          └─ children: List<TableOfContentsItem>  // recursive
```

### Index/Library Structure
```dart
Index
  └─ items: List<IndexItem>
      ├─ name: String
      ├─ path: String
      └─ type: IndexItemType
```

## Code Style

- **Minimal stubs** for incomplete classes - methods can return early or be empty
- **No TODO comments** - just implement what's needed
- **UTF-8 encoding** for all file I/O
- **Dependency injection** pattern throughout

## Testing Notes

- Tests use mock/stub implementations of `FileSystem`
- Each phase can be tested independently

## Build Commands

```bash
# Analyze
dart analyze

# Format
dart format .

# Test
dart test
```

## File Organization

- `lib/phase_1_navigation/` - Discovery and hierarchy walking
- `lib/phase_2_extraction/` - TOC extraction and section splitting
- `lib/phase_3_processing/` - HTML cleaning and normalization
- `lib/phase_4_output/` - File writing and folder organization
- `lib/phase_5_orchestration/` - High-level coordination

## Development Workflow

When adding new features:
1. Check ARCHITECTURE.md for class responsibilities
2. Maintain phase separation - don't mix concerns
3. Keep dependencies injected via constructor
4. Pass data/materials as method parameters
5. Return results rather than mutating state

## Stub Files (Minimal Implementation)

Many files are stubs that can be filled in as needed. Don't over-engineer them until the functionality is actually required.
