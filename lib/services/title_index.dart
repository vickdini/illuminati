import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import 'catalog_service.dart';

/// One row of the Gutenberg catalog, reduced to what search needs.
class IndexEntry {
  final int id;
  final String title;
  final List<String> authors;
  final List<String> languages;

  /// Folded (lowercase, accent-free) title, author and subject text.
  final String titleKey;
  final String authorKey;
  final String subjectKey;

  const IndexEntry(
    this.id,
    this.title,
    this.authors,
    this.languages,
    this.titleKey,
    this.authorKey,
    this.subjectKey,
  );

  Book toBook() => Book(
    id: id,
    title: title,
    authors: authors,
    languages: languages,
    coverUrl: CatalogService.coverUrlFor(id),
    epubUrl: CatalogService.epubUrlFor(id),
  );
}

/// A local, offline copy of the whole Project Gutenberg catalog
/// (`pg_catalog.csv`, refreshed weekly). Unlike the server search, which only
/// matches whole words, it finds any part of a title or author name and
/// ignores accents: "miserab" and "misérable" both find "Los miserables".
class TitleIndex {
  static const catalogUrl =
      '${CatalogService.site}/cache/epub/feeds/pg_catalog.csv.gz';
  static const maxAge = Duration(days: 7);

  List<IndexEntry>? _entries;
  Future<List<IndexEntry>?>? _loading;

  TitleIndex();
  @visibleForTesting
  TitleIndex.forTesting(List<IndexEntry> entries) : _entries = entries;

  bool get ready => _entries != null;

  /// Loads the index (downloading it if missing or stale). Safe to call often;
  /// returns null if the catalog is unavailable (e.g. first launch offline).
  Future<List<IndexEntry>?> load() {
    if (_entries != null) return Future.value(_entries);
    return _loading ??= _load().then((e) {
      _entries = e;
      _loading = null;
      return e;
    });
  }

  Future<List<IndexEntry>?> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'pg_catalog.csv.gz'));
      final exists = await file.exists();
      final stale =
          !exists ||
          DateTime.now().difference(await file.lastModified()) > maxAge;
      if (stale) {
        try {
          final res = await http
              .get(
                Uri.parse(catalogUrl),
                headers: {'User-Agent': CatalogService.userAgent},
              )
              .timeout(const Duration(seconds: 90));
          if (res.statusCode == 200 && res.bodyBytes.length > 100000) {
            final tmp = File('${file.path}.tmp');
            await tmp.writeAsBytes(res.bodyBytes);
            await tmp.rename(file.path);
          }
        } catch (e) {
          debugPrint('Catalog index download failed: $e');
        }
      }
      if (!await file.exists()) return null;
      return await compute(parseCatalogGz, await file.readAsBytes());
    } catch (e) {
      debugPrint('Catalog index unavailable: $e');
      return null;
    }
  }

  /// Books whose title or author contains every word of [query].
  /// Best matches first: title starts with the query, then the query appears
  /// at the start of a title word, then anywhere in the title, then author.
  List<Book> search(
    String query, {
    String? language,
    String? subject,
    int limit = 300,
  }) {
    final entries = _entries;
    if (entries == null) return const [];
    final q = fold(query).trim();
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final subjectWords = fold(
      subject ?? '',
    ).split(' ').where((w) => w.isNotEmpty).toList();

    final scored = <(int, IndexEntry)>[];
    for (final e in entries) {
      if (language != null &&
          language.isNotEmpty &&
          !e.languages.contains(language)) {
        continue;
      }
      if (!subjectWords.every(e.subjectKey.contains)) continue;
      var inTitle = true;
      var ok = true;
      for (final w in words) {
        if (e.titleKey.contains(w)) continue;
        inTitle = false;
        if (!e.authorKey.contains(w)) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;

      final int score;
      if (e.titleKey.startsWith(q)) {
        score = 0;
      } else if (e.titleKey.contains(' $q') || _wordStart(e.titleKey, q)) {
        score = 1;
      } else if (e.titleKey.contains(q)) {
        score = 2;
      } else if (inTitle) {
        score = 3;
      } else {
        score = 4;
      }
      scored.add((score, e));
    }
    // Lower ebook numbers are generally the older, better-known classics.
    scored.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2.id - b.$2.id);
    return [for (final s in scored.take(limit)) s.$2.toBook()];
  }

  static bool _wordStart(String text, String q) {
    var i = text.indexOf(q);
    while (i >= 0) {
      if (i == 0 || !_isLetter(text.codeUnitAt(i - 1))) return true;
      i = text.indexOf(q, i + 1);
    }
    return false;
  }

  static bool _isLetter(int c) =>
      (c >= 0x61 && c <= 0x7a) || (c >= 0x30 && c <= 0x39) || c > 0x7f;
}

// ---------------------------------------------------------------------------
// Text folding: lowercase and strip accents so "Misérables" == "miserables".

const _accented =
    'àáâãäåāăąçćčďđèéêëēėęěìíîïīįñńňòóôõöøōőùúûüūůűųýÿźżžśšşţťŕřłğ';
const _plain = 'aaaaaaaaacccddeeeeeeeeiiiiiinnnooooooooouuuuuuuuyyzzzsssttrrlg';
final _foldMap = {
  for (var i = 0; i < _accented.length; i++)
    _accented.codeUnitAt(i): _plain.codeUnitAt(i),
};

String fold(String s) {
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final c in lower.codeUnits) {
    if (c < 0x80) {
      out.writeCharCode(c);
    } else if (_foldMap.containsKey(c)) {
      out.writeCharCode(_foldMap[c]!);
    } else if (c == 0x00df) {
      out.write('ss');
    } else if (c == 0x0153) {
      out.write('oe');
    } else if (c == 0x00e6) {
      out.write('ae');
    } else if (c == 0x2019 || c == 0x2018) {
      out.write("'");
    } else {
      out.writeCharCode(c);
    }
  }
  return out.toString();
}

/// Like [fold] but never changes the string's length, so match positions in
/// the folded text are valid in the original (used for in-book search).
String foldSameLength(String s) {
  final out = StringBuffer();
  for (final c in s.codeUnits) {
    if (c < 0x80) {
      out.writeCharCode(c >= 0x41 && c <= 0x5a ? c + 32 : c);
      continue;
    }
    final lower = String.fromCharCode(c).toLowerCase();
    final lc = lower.length == 1 ? lower.codeUnitAt(0) : c;
    final mapped = _foldMap[lc];
    if (mapped != null) {
      out.writeCharCode(mapped);
    } else if (lc == 0x2019 || lc == 0x2018) {
      out.write("'");
    } else {
      out.writeCharCode(lc);
    }
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Parsing (runs on a background isolate).

/// Parses the gzipped Gutenberg catalog CSV:
/// Text#, Type, Issued, Title, Language, Authors, Subjects, LoCC, Bookshelves
List<IndexEntry> parseCatalogGz(List<int> gz) =>
    parseCatalogCsv(utf8.decode(gzip.decode(gz), allowMalformed: true));

List<IndexEntry> parseCatalogCsv(String csv) {
  final rows = _parseCsv(csv);
  final out = <IndexEntry>[];
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (r.length < 7 || r[1] != 'Text') continue;
    final id = int.tryParse(r[0]);
    if (id == null) continue;
    final title = r[3].replaceAll(RegExp(r'\s+'), ' ').trim();
    final langs = r[4]
        .split(';')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // "Hugo, Victor, 1802-1885; J. A. R. [Translator]" -> main authors only.
    final people = r[5]
        .split(';')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    final main = people.where((a) => !a.contains('[')).toList();
    final authors = (main.isEmpty ? people.take(1) : main)
        .map((a) => Book.prettyName(a.replaceAll(RegExp(r'\s*\[.*?\]'), '')))
        .where((a) => a.isNotEmpty)
        .toList();

    out.add(
      IndexEntry(
        id,
        title,
        authors,
        langs,
        fold(title),
        fold(r[5]),
        fold('${r[6]} ${r.length > 8 ? r[8] : ''}'),
      ),
    );
  }
  return out;
}

/// Minimal RFC 4180 CSV parser (quoted fields may contain commas, quotes
/// and newlines).
List<List<String>> _parseCsv(String s) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (inQuotes) {
      if (c == 0x22) {
        if (i + 1 < s.length && s.codeUnitAt(i + 1) == 0x22) {
          field.writeCharCode(0x22);
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.writeCharCode(c);
      }
    } else if (c == 0x22) {
      inQuotes = true;
    } else if (c == 0x2c) {
      row.add(field.toString());
      field.clear();
    } else if (c == 0x0a) {
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else if (c != 0x0d) {
      field.writeCharCode(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
