/// A book from the free catalog (Project Gutenberg).
class Book {
  final int id;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final String? epubUrl;
  final List<String> subjects;
  final List<String> languages;
  final int downloadCount;
  final String? summary;

  const Book({
    required this.id,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.epubUrl,
    this.subjects = const [],
    this.languages = const [],
    this.downloadCount = 0,
    this.summary,
  });

  String get authorLine =>
      authors.isEmpty ? 'Unknown author' : authors.join(', ');

  /// Gutenberg lists authors as "Austen, Jane"; show them as "Jane Austen".
  static String prettyName(String raw) {
    // Drop lifespans such as ", 1694-1778" or ", 1812-1870 [Contributor]".
    raw = raw.replaceFirst(RegExp(r',\s*(BCE?\s*)?\d.*$'), '');
    final parts = raw.split(', ');
    if (parts.length == 2 && !parts[1].contains(RegExp(r'\d'))) {
      return '${parts[1]} ${parts[0]}'.trim();
    }
    return raw.trim();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authors': authors,
        'coverUrl': coverUrl,
        'epubUrl': epubUrl,
        'subjects': subjects,
        'languages': languages,
        'downloadCount': downloadCount,
        'summary': summary,
      };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'] as int,
        title: j['title'] as String,
        authors: (j['authors'] as List).cast<String>(),
        coverUrl: j['coverUrl'] as String?,
        epubUrl: j['epubUrl'] as String?,
        subjects: ((j['subjects'] as List?) ?? []).cast<String>(),
        languages: ((j['languages'] as List?) ?? []).cast<String>(),
        downloadCount: j['downloadCount'] as int? ?? 0,
        summary: j['summary'] as String?,
      );
}

/// A book the user has downloaded, with its local files and reading position.
class LibraryEntry {
  final Book book;
  final String epubPath;
  final String? coverPath;
  final DateTime addedAt;
  DateTime? lastOpened;

  /// Index of the chapter the reader was on.
  int chapter;

  /// Index of the first visible paragraph inside [chapter].
  int block;

  /// Overall progress through the book, 0..1.
  double progress;

  /// Opening words of the paragraph at [chapter]/[block], used to find the
  /// reading position again if the book is re-downloaded or re-parsed.
  String anchor;

  LibraryEntry({
    required this.book,
    required this.epubPath,
    this.coverPath,
    required this.addedAt,
    this.lastOpened,
    this.chapter = 0,
    this.block = 0,
    this.progress = 0,
    this.anchor = '',
  });

  Map<String, dynamic> toJson() => {
        'book': book.toJson(),
        'epubPath': epubPath,
        'coverPath': coverPath,
        'addedAt': addedAt.toIso8601String(),
        'lastOpened': lastOpened?.toIso8601String(),
        'chapter': chapter,
        'block': block,
        'progress': progress,
        'anchor': anchor,
      };

  factory LibraryEntry.fromJson(Map<String, dynamic> j) => LibraryEntry(
        book: Book.fromJson((j['book'] as Map).cast<String, dynamic>()),
        epubPath: j['epubPath'] as String,
        coverPath: j['coverPath'] as String?,
        addedAt: DateTime.parse(j['addedAt'] as String),
        lastOpened: j['lastOpened'] == null
            ? null
            : DateTime.parse(j['lastOpened'] as String),
        chapter: j['chapter'] as int? ?? 0,
        block: j['block'] as int? ?? 0,
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
        anchor: j['anchor'] as String? ?? '',
      );
}
