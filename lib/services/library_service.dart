import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import '../models/shelf.dart';
import '../sources/book_source.dart';
import 'catalog_service.dart';
import 'title_index.dart' show fold;

/// Library views: everything, by state, or one shelf (`shelf:<id>`).
class LibraryView {
  static const all = 'all';
  static const downloaded = 'downloaded';
  static const wantToRead = 'want';
  static const reading = 'reading';
  static const finished = 'finished';
  static String shelf(String id) => 'shelf:$id';
}

/// Owns the user's library: saved and downloaded books, reading state and
/// shelves (`library.json`), plus the files on disk.
class LibraryService extends ChangeNotifier {
  final SourceRegistry sources;
  LibraryService(this.sources);

  late Directory _root;
  final Map<int, LibraryEntry> _entries = {};
  final List<Shelf> _shelves = [];

  /// Book id -> download progress (0..1), or null while the size is unknown.
  final Map<int, double?> downloads = {};

  bool ready = false;

  File get _indexFile => File(p.join(_root.path, 'library.json'));

  /// Every library entry, most recently read first.
  List<LibraryEntry> get entries => sortEntries(_entries.values, LibrarySort.recent);

  /// Downloaded books only, most recently read first (the home screen row).
  List<LibraryEntry> get downloaded => entries.where((e) => e.isDownloaded).toList();

  List<Shelf> get shelves => List.unmodifiable(_shelves);

  /// Highlights, notes and bookmarks for a book.
  File annotationsFile(int id) => File(p.join(_root.path, 'notes', '$id.json'));

  /// In the library (downloaded or saved for later).
  bool has(int id) => _entries.containsKey(id);
  bool isDownloaded(int id) => _entries[id]?.isDownloaded ?? false;
  LibraryEntry? entry(int id) => _entries[id];
  bool isDownloading(int id) => downloads.containsKey(id);

  Future<void> init() async {
    final support = await getApplicationSupportDirectory();
    _root = Directory(p.join(support.path, 'library'));
    await Directory(p.join(_root.path, 'books')).create(recursive: true);
    await Directory(p.join(_root.path, 'covers')).create(recursive: true);

    if (await _indexFile.exists()) {
      try {
        load(jsonDecode(await _indexFile.readAsString()));
      } catch (e) {
        debugPrint('Could not read library index: $e');
      }
    }
    ready = true;
    notifyListeners();
  }

  /// Points the service at [dir] instead of the app-support folder.
  @visibleForTesting
  void useDirectory(Directory dir) => _root = dir;

  /// Reads `library.json`: a list of entries (version 1) or an object with
  /// entries and shelves (version 2).
  @visibleForTesting
  void load(Object? data) {
    final List rawEntries;
    var rawShelves = const <dynamic>[];
    if (data is List) {
      rawEntries = data;
    } else if (data is Map) {
      rawEntries = (data['entries'] as List?) ?? const [];
      rawShelves = (data['shelves'] as List?) ?? const [];
    } else {
      return;
    }
    for (final item in rawEntries) {
      final e = LibraryEntry.fromJson((item as Map).cast<String, dynamic>());
      // A deleted or moved file just makes the book "not downloaded".
      if (e.epubPath != null && !File(e.epubPath!).existsSync()) e.epubPath = null;
      _entries[e.book.id] = e;
    }
    for (final s in rawShelves) {
      final shelf = Shelf.fromJson((s as Map).cast<String, dynamic>());
      shelf.bookIds.removeWhere((id) => !_entries.containsKey(id));
      _shelves.add(shelf);
    }
  }

  @visibleForTesting
  Map<String, dynamic> toJson() => {
        'version': 2,
        'entries': _entries.values.map((e) => e.toJson()).toList(),
        'shelves': _shelves.map((s) => s.toJson()).toList(),
      };

  Future<void> _saving = Future.value();

  /// Completes when every change made so far is on disk.
  Future<void> get saved => _saving;

  /// Queues a write of library.json, so overlapping saves never collide.
  Future<void> _save() => _saving = _saving.then((_) => _write()).catchError((Object e) {
        debugPrint('Could not save library: $e');
      });

  Future<void> _write() async {
    final tmp = File('${_indexFile.path}.tmp');
    await tmp.writeAsString(jsonEncode(toJson()));
    await tmp.rename(_indexFile.path);
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---------- Views, sorting ----------

  /// Entries shown in a [LibraryView], optionally narrowed by [filter]
  /// (matches title or author, ignoring case and accents).
  List<LibraryEntry> entriesIn(String view, {LibrarySort sort = LibrarySort.recent, String filter = ''}) {
    Iterable<LibraryEntry> list = _entries.values;
    if (view.startsWith('shelf:')) {
      final shelf = _shelves.where((s) => 'shelf:${s.id}' == view).firstOrNull;
      list = shelf == null ? const [] : shelf.bookIds.map((id) => _entries[id]).whereType<LibraryEntry>();
    } else {
      list = switch (view) {
        LibraryView.downloaded => list.where((e) => e.isDownloaded),
        LibraryView.wantToRead => list.where((e) => e.status == ReadingStatus.wantToRead),
        LibraryView.reading => list.where((e) => e.isReading),
        LibraryView.finished => list.where((e) => e.status == ReadingStatus.finished),
        _ => list,
      };
    }
    final words = fold(filter).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isNotEmpty) {
      list = list.where((e) {
        final text = fold('${e.book.title} ${e.book.authorLine}');
        return words.every(text.contains);
      });
    }
    return sortEntries(list, sort);
  }

  int countIn(String view) => entriesIn(view).length;

  static List<LibraryEntry> sortEntries(Iterable<LibraryEntry> entries, LibrarySort sort) {
    final list = entries.toList();
    int byTitle(LibraryEntry a, LibraryEntry b) => _titleKey(a.book.title).compareTo(_titleKey(b.book.title));
    DateTime recent(LibraryEntry e) => e.lastOpened ?? e.addedAt;
    list.sort((a, b) {
      final c = switch (sort) {
        LibrarySort.recent => recent(b).compareTo(recent(a)),
        LibrarySort.title => 0,
        LibrarySort.author => _authorKey(a.book).compareTo(_authorKey(b.book)),
        LibrarySort.progress => b.progress.compareTo(a.progress),
        LibrarySort.added => b.addedAt.compareTo(a.addedAt),
      };
      return c != 0 ? c : byTitle(a, b);
    });
    return list;
  }

  /// "The Time Machine" sorts under T for "Time", as in a bookshop.
  static String _titleKey(String title) => fold(title)
      .replaceFirst(RegExp(r"^(the|a|an|el|la|los|las|le|les|l'|il|lo|gli|die|der|das|o|os|as) "), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
      .trim();

  /// By surname: "Jane Austen" -> "austen jane"; unknown authors sort last.
  static String _authorKey(Book book) {
    if (book.authors.isEmpty) return '￿';
    final parts = fold(book.authors.first).split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.length < 2) return parts.join();
    return '${parts.last} ${parts.sublist(0, parts.length - 1).join(' ')}';
  }

  // ---------- Saving books, status ----------

  /// Adds [book] to the library without downloading it (no-op if present).
  LibraryEntry add(Book book, {ReadingStatus status = ReadingStatus.none}) {
    final existing = _entries[book.id];
    if (existing != null) return existing;
    final e = LibraryEntry(book: book, addedAt: DateTime.now(), status: status);
    _entries[book.id] = e;
    _changed();
    return e;
  }

  /// Sets a book's status, adding it to the library first if needed.
  void setStatus(Book book, ReadingStatus status) {
    final e = _entries[book.id] ?? add(book);
    e.status = status;
    _changed();
  }

  // ---------- Shelves ----------

  Shelf createShelf(String name) {
    final shelf = Shelf(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: name.trim(),
      created: DateTime.now(),
    );
    _shelves.add(shelf);
    _changed();
    return shelf;
  }

  void renameShelf(Shelf shelf, String name) {
    shelf.name = name.trim();
    _changed();
  }

  /// Deletes the shelf only; its books stay in the library.
  void deleteShelf(Shelf shelf) {
    _shelves.remove(shelf);
    _changed();
  }

  List<Shelf> shelvesOf(int bookId) => _shelves.where((s) => s.contains(bookId)).toList();

  /// Puts [book] on [shelf] (adding it to the library if needed), or takes
  /// it off.
  void setOnShelf(Shelf shelf, Book book, bool on) {
    if (on) {
      add(book);
      if (!shelf.contains(book.id)) shelf.bookIds.add(book.id);
    } else {
      shelf.bookIds.remove(book.id);
    }
    _changed();
  }

  // ---------- Downloading ----------

  /// Downloads the EPUB (and cover) for [book] into the library.
  /// With [replace], re-downloads a book already downloaded (e.g. to get
  /// the illustrated edition), keeping the reading position and notes.
  Future<void> download(Book book, {bool replace = false}) async {
    if ((isDownloaded(book.id) && !replace) || isDownloading(book.id)) return;

    downloads[book.id] = null;
    notifyListeners();

    final epubFile = File(p.join(_root.path, 'books', '${book.id}.epub'));
    final partFile = File('${epubFile.path}.part');
    final client = http.Client();
    try {
      // Get the full record (summary, subjects, best EPUB link) unless we have it.
      final previousUrl = book.epubUrl;
      if (replace || (book.summary == null && book.subjects.isEmpty)) {
        try {
          book = await sources.details(book);
        } catch (e) {
          if (replace) rethrow;
          // Fall back to the standard EPUB URL from the listing.
        }
      }
      if (replace && book.epubUrl == previousUrl) {
        throw CatalogException('There is no other edition of this book.');
      }
      final url = book.epubUrl;
      if (url == null) {
        throw CatalogException('This title has no e-book edition (it may be an audio book).');
      }
      final req = http.Request('GET', Uri.parse(url))
        ..headers['User-Agent'] = CatalogService.userAgent;
      // Generous: Wikisource EPUBs are built on demand before the first byte.
      final http.StreamedResponse res;
      try {
        res = await client.send(req).timeout(const Duration(seconds: 150));
      } on TimeoutException {
        throw CatalogException(book.source == 'wikisource'
            ? _wikisourceTooBig
            : 'The download took too long. Check your connection and try again.');
      }
      if (res.statusCode != 200) {
        // WS Export gives up on very long works (e.g. multi-volume novels).
        if (book.source == 'wikisource' && res.statusCode >= 500) {
          throw CatalogException(_wikisourceTooBig);
        }
        throw CatalogException('Download failed (${res.statusCode}).');
      }
      final total = res.contentLength;
      var received = 0;
      final sink = partFile.openWrite();
      try {
        await for (final chunk in res.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total != null && total > 0) {
            downloads[book.id] = received / total;
            notifyListeners();
          }
        }
      } finally {
        await sink.close();
      }
      // An EPUB is a ZIP archive and must start with "PK".
      final head = await partFile.openRead(0, 2).first;
      if (head.length < 2 || head[0] != 0x50 || head[1] != 0x4B) {
        throw CatalogException('The downloaded file is not a valid EPUB.');
      }
      await partFile.rename(epubFile.path);

      String? coverPath;
      if (book.coverUrl != null) {
        try {
          final c = await client
              .get(Uri.parse(book.coverUrl!),
                  headers: {'User-Agent': CatalogService.userAgent})
              .timeout(const Duration(seconds: 30));
          if (c.statusCode == 200) {
            final f = File(p.join(_root.path, 'covers', '${book.id}.jpg'));
            await f.writeAsBytes(c.bodyBytes);
            coverPath = f.path;
          }
        } catch (_) {
          // A missing cover is not fatal; a placeholder is drawn instead.
        }
      }

      // Keep everything the user already had for this book: status,
      // shelves (by id), reading position.
      final old = _entries[book.id];
      _entries[book.id] = LibraryEntry(
        book: book,
        epubPath: epubFile.path,
        coverPath: coverPath ?? old?.coverPath,
        addedAt: old?.addedAt ?? DateTime.now(),
        lastOpened: old?.lastOpened,
        status: old?.status ?? ReadingStatus.none,
        chapter: old?.chapter ?? 0,
        block: old?.block ?? 0,
        progress: old?.progress ?? 0,
        anchor: old?.anchor ?? '',
      );
      await _save();
    } catch (e) {
      if (await partFile.exists()) await partFile.delete();
      rethrow;
    } finally {
      client.close();
      downloads.remove(book.id);
      notifyListeners();
    }
  }

  static const _wikisourceTooBig =
      'Wikisource could not prepare this book: it is too long for their EPUB '
      'service. Try one of its volumes, or look for it in another catalog.';

  /// Deletes the downloaded file to free space; the book stays in the
  /// library with its status, shelves, notes and reading position.
  Future<void> removeDownload(int id) async {
    final e = _entries[id];
    final path = e?.epubPath;
    if (e == null || path == null) return;
    e.epubPath = null;
    _changed();
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  /// Removes the book from the library entirely: file, cover, notes, shelves.
  Future<void> remove(int id) async {
    final e = _entries.remove(id);
    if (e == null) return;
    for (final s in _shelves) {
      s.bookIds.remove(id);
    }
    notifyListeners();
    for (final path in [e.epubPath, e.coverPath, annotationsFile(id).path]) {
      if (path == null) continue;
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    await _save();
  }

  /// Called when a book is opened: it's now being read, not "want to read".
  void markOpened(int id) {
    final e = _entries[id];
    if (e == null) return;
    e.lastOpened = DateTime.now();
    if (e.status == ReadingStatus.wantToRead) e.status = ReadingStatus.none;
    _changed();
  }

  Future<void> saveProgress(int id,
      {required int chapter,
      required int block,
      required double progress,
      String anchor = ''}) async {
    final e = _entries[id];
    if (e == null) return;
    e
      ..chapter = chapter
      ..block = block
      ..progress = progress.clamp(0.0, 1.0)
      ..anchor = anchor;
    notifyListeners();
    await _save();
  }
}
