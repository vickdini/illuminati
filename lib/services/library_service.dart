import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import '../sources/book_source.dart';
import 'catalog_service.dart';

/// Owns the user's downloaded books: files on disk plus `library.json`.
class LibraryService extends ChangeNotifier {
  final SourceRegistry sources;
  LibraryService(this.sources);

  late Directory _root;
  final Map<int, LibraryEntry> _entries = {};

  /// Book id -> download progress (0..1), or null while the size is unknown.
  final Map<int, double?> downloads = {};

  bool ready = false;

  File get _indexFile => File(p.join(_root.path, 'library.json'));

  /// Downloaded books, most recently read first.
  List<LibraryEntry> get entries {
    final list = _entries.values.toList();
    list.sort((a, b) {
      final ta = a.lastOpened ?? a.addedAt;
      final tb = b.lastOpened ?? b.addedAt;
      return tb.compareTo(ta);
    });
    return list;
  }

  /// Highlights, notes and bookmarks for a book.
  File annotationsFile(int id) => File(p.join(_root.path, 'notes', '$id.json'));

  bool has(int id) => _entries.containsKey(id);
  LibraryEntry? entry(int id) => _entries[id];
  bool isDownloading(int id) => downloads.containsKey(id);

  Future<void> init() async {
    final support = await getApplicationSupportDirectory();
    _root = Directory(p.join(support.path, 'library'));
    await Directory(p.join(_root.path, 'books')).create(recursive: true);
    await Directory(p.join(_root.path, 'covers')).create(recursive: true);

    if (await _indexFile.exists()) {
      try {
        final list = jsonDecode(await _indexFile.readAsString()) as List;
        for (final item in list) {
          final e = LibraryEntry.fromJson((item as Map).cast<String, dynamic>());
          if (File(e.epubPath).existsSync()) _entries[e.book.id] = e;
        }
      } catch (e) {
        debugPrint('Could not read library index: $e');
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _saving = Future.value();

  /// Queues a write of library.json, so overlapping saves never collide.
  Future<void> _save() => _saving = _saving.then((_) => _write()).catchError((Object e) {
        debugPrint('Could not save library: $e');
      });

  Future<void> _write() async {
    final tmp = File('${_indexFile.path}.tmp');
    await tmp.writeAsString(
        jsonEncode(_entries.values.map((e) => e.toJson()).toList()));
    await tmp.rename(_indexFile.path);
  }

  /// Downloads the EPUB (and cover) for [book] into the library.
  /// With [replace], re-downloads a book already in the library (e.g. to get
  /// the illustrated edition), keeping the reading position and notes.
  Future<void> download(Book book, {bool replace = false}) async {
    if ((has(book.id) && !replace) || isDownloading(book.id)) return;

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

      final old = _entries[book.id];
      _entries[book.id] = LibraryEntry(
        book: book,
        epubPath: epubFile.path,
        coverPath: coverPath ?? old?.coverPath,
        addedAt: old?.addedAt ?? DateTime.now(),
        lastOpened: old?.lastOpened,
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

  Future<void> remove(int id) async {
    final e = _entries.remove(id);
    if (e == null) return;
    notifyListeners();
    for (final path in [e.epubPath, e.coverPath, annotationsFile(id).path]) {
      if (path == null) continue;
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    await _save();
  }

  void markOpened(int id) {
    final e = _entries[id];
    if (e == null) return;
    e.lastOpened = DateTime.now();
    notifyListeners();
    _save();
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
