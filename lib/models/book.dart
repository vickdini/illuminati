/// A free book from one of the catalogs (see `lib/sources/`).
class Book {
  /// Library key. Gutenberg books use their ebook number; books from other
  /// sources use [stableId] of their source key (always negative).
  final int id;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final String? epubUrl;
  final List<String> subjects;
  final List<String> languages;
  final int downloadCount;
  final String? summary;

  /// Which catalog the book comes from, e.g. `gutenberg`, `standardebooks`.
  final String source;

  /// The book's key in its source (a path, page title or identifier).
  final String? sourceId;

  /// The book's page on the source's website.
  final String? webUrl;

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
    this.source = 'gutenberg',
    this.sourceId,
    this.webUrl,
  });

  /// A negative id derived from a source key (64-bit FNV-1a, 52 bits kept),
  /// so it never collides with Gutenberg ebook numbers.
  static int stableId(String source, String key) {
    var h = 0xcbf29ce484222325;
    for (final c in '$source:$key'.codeUnits) {
      h ^= c;
      h *= 0x100000001b3;
    }
    return -((h & 0xFFFFFFFFFFFFF) + 1);
  }

  Book copyWith({
    String? title,
    List<String>? authors,
    String? coverUrl,
    String? epubUrl,
    List<String>? subjects,
    List<String>? languages,
    int? downloadCount,
    String? summary,
  }) => Book(
    id: id,
    title: title ?? this.title,
    authors: authors ?? this.authors,
    coverUrl: coverUrl ?? this.coverUrl,
    epubUrl: epubUrl ?? this.epubUrl,
    subjects: subjects ?? this.subjects,
    languages: languages ?? this.languages,
    downloadCount: downloadCount ?? this.downloadCount,
    summary: summary ?? this.summary,
    source: source,
    sourceId: sourceId,
    webUrl: webUrl,
  );

  String get authorLine =>
      authors.isEmpty ? 'Unknown author' : authors.join(', ');

  /// Gutenberg lists authors as "Austen, Jane"; show them as "Jane Austen".
  static String prettyName(String raw) {
    // Drop lifespans such as ", 1694-1778", ", ca. 1571-1631" or
    // ", 1812-1870 [Contributor]".
    raw = raw.replaceFirst(
      RegExp(r',\s*(ca\.?\s*|fl\.?\s*|b\.\s*|d\.\s*|BCE?\s*)?\d.*$'),
      '',
    );
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
    'source': source,
    'sourceId': sourceId,
    'webUrl': webUrl,
  };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
    source: j['source'] as String? ?? 'gutenberg',
    sourceId: j['sourceId'] as String?,
    webUrl: j['webUrl'] as String?,
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

/// Reading state the user sets (or the reader sets on finishing a book).
enum ReadingStatus { none, wantToRead, finished }

/// A book in the user's library: its details, reading position and status.
/// It may be downloaded (has [epubPath]) or just saved for later.
class LibraryEntry {
  final Book book;

  /// The downloaded EPUB, or null if the book isn't downloaded (yet).
  String? epubPath;
  final String? coverPath;
  final DateTime addedAt;
  DateTime? lastOpened;
  ReadingStatus status;

  bool get isDownloaded => epubPath != null;

  /// Opened and partly read, but not finished.
  bool get isReading =>
      isDownloaded && progress > 0 && status != ReadingStatus.finished;

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
    this.epubPath,
    this.coverPath,
    required this.addedAt,
    this.lastOpened,
    this.status = ReadingStatus.none,
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
    'status': status.name,
  };

  factory LibraryEntry.fromJson(Map<String, dynamic> j) => LibraryEntry(
    book: Book.fromJson((j['book'] as Map).cast<String, dynamic>()),
    epubPath: j['epubPath'] as String?,
    status: ReadingStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => ReadingStatus.none,
    ),
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
