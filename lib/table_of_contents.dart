/// Represents a section within a book's content
class ContentSection {
  final String title;
  final String anchor;

  ContentSection({
    required this.title,
    required this.anchor,
  });
}

/// A table of contents item - either a leaf pointing to content, or a group with children
sealed class TableOfContentsItem {
  String get title;
}

/// A leaf item that points to actual content
class ContentItem extends TableOfContentsItem {
  @override
  final String title;
  final ContentSection section;

  ContentItem({required this.title, required this.section});
}

/// A group item that contains nested items
class GroupItem extends TableOfContentsItem {
  @override
  final String title;
  final List<TableOfContentsItem> children;

  GroupItem({required this.title, required this.children});
}

/// Represents the full table of contents hierarchy
class TableOfContents {
  final List<TableOfContentsItem> items;

  TableOfContents(this.items);
}
