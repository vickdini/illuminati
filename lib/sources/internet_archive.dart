import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../services/title_index.dart' show fold;
import 'book_source.dart';

/// Internet Archive (archive.org): scans of old printed books, with EPUBs
/// made by OCR (text quality varies). Its copyright metadata is unreliable,
/// so only books published long enough ago to be public domain in the US are
/// listed, and only items that are free to download (not lending-library).
class InternetArchiveSource extends BookSource {
  final http.Client _client;
  InternetArchiveSource([http.Client? client]) : _client = client ?? http.Client();

  @override
  String get id => 'archive';
  @override
  String get name => 'Internet Archive';
  @override
  String get tagline => 'Scans of old printed editions (text made by OCR)';

  /// Works published 95 or more years ago are public domain in the US:
  /// in 2026 that means 1930 and earlier.
  static int get latestPublicDomainYear => DateTime.now().year - 96;

  /// Catalog languages -> Internet Archive language values.
  static const _languages = {
    'en': ['eng', 'English'],
    'es': ['spa', 'Spanish'],
    'fr': ['fre', 'fra', 'French'],
    'de': ['ger', 'deu', 'German'],
    'it': ['ita', 'Italian'],
    'pt': ['por', 'Portuguese'],
    'nl': ['dut', 'nld', 'Dutch'],
    'fi': ['fin', 'Finnish'],
  };

  @override
  bool supports({required String language, required String subject}) =>
      language.isEmpty || _languages.containsKey(language);

  final _cache = FeaturedCache();

  @override
  Future<List<Book>> featured({required String language, required String subject}) =>
      _cache.get('$language|$subject',
          () => _search(query: '', language: language, subject: subject, literature: true));

  @override
  Future<List<Book>> search(String query, {required String language, required String subject}) =>
      _search(query: query, language: language, subject: subject);

  /// Literary subjects in several languages, so the default row shows
  /// literature rather than the archive's most-downloaded dictionaries.
  static const _literature = 'fiction OR novel OR novela OR novelas OR literature OR literatura '
      'OR poetry OR poesia OR drama OR teatro OR cuentos OR stories OR roman OR romans '
      'OR litterature OR poesie OR romane OR dichtung OR romanzi OR racconti';

  /// The archive's search rejects accented letters: "misérables" -> "miserables".
  static String _ascii(String s) =>
      plainQuery(fold(s)).replaceAll(RegExp(r'[^\x20-\x7e]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String buildQuery(
      {required String query, required String language, required String subject, bool literature = false}) {
    final parts = [
      'mediatype:texts',
      'format:EPUB',
      '-access-restricted-item:true',
      'year:[1500 TO $latestPublicDomainYear]',
    ];
    final langs = _languages[language];
    if (langs != null) parts.add('language:(${langs.map((l) => '"$l"').join(' OR ')})');
    final s = _ascii(subject);
    if (s.isNotEmpty) {
      parts.add('subject:($s)');
    } else if (literature) {
      parts.add('subject:($_literature)');
      parts.add('-subject:(dictionaries OR dictionary OR grammar OR vocabulary)');
      parts.add('-title:(dictionary OR grammar OR vocabulary OR diccionario OR dictionnaire)');
    }
    final q = _ascii(query);
    if (q.isNotEmpty) parts.add('(title:($q) OR creator:($q))');
    return parts.join(' AND ');
  }

  Future<List<Book>> _search(
      {required String query,
      required String language,
      required String subject,
      bool literature = false}) async {
    final uri = Uri.parse('https://archive.org/advancedsearch.php').replace(queryParameters: {
      'q': buildQuery(query: query, language: language, subject: subject, literature: literature),
      'fl[]': ['identifier', 'title', 'creator', 'language', 'year', 'downloads'],
      'sort[]': 'downloads desc',
      'rows': '24',
      'output': 'json',
    });
    final res = await sourceGet(_client, uri);
    return parseSearch(utf8.decode(res.bodyBytes));
  }

  static List<Book> parseSearch(String json) {
    final docs = (((jsonDecode(json) as Map)['response'] as Map?)?['docs'] as List?) ?? const [];
    final books = <Book>[];
    for (final raw in docs) {
      final d = raw as Map<String, dynamic>;
      final ident = d['identifier'] as String?;
      final title = _first(d['title']);
      if (ident == null || title == null) continue;
      books.add(Book(
        id: Book.stableId('archive', ident),
        source: 'archive',
        sourceId: ident,
        title: title.trim(),
        authors: _list(d['creator']).take(2).map(Book.prettyName).toList(),
        languages: _list(d['language']),
        downloadCount: (d['downloads'] as num?)?.toInt() ?? 0,
        coverUrl: 'https://archive.org/services/img/$ident',
        epubUrl: 'https://archive.org/download/$ident/$ident.epub',
        webUrl: 'https://archive.org/details/$ident',
      ));
    }
    return books;
  }

  @override
  Future<Book> details(Book book) async {
    final ident = book.sourceId;
    if (ident == null) return book;
    final res = await sourceGet(_client, Uri.parse('https://archive.org/metadata/$ident'));
    return parseMetadata(book, utf8.decode(res.bodyBytes));
  }

  static Book parseMetadata(Book book, String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final meta = (data['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
    final files = (data['files'] as List?) ?? const [];
    final epub = files
        .map((f) => (f as Map)['name'] as String?)
        .whereType<String>()
        .where((n) => n.toLowerCase().endsWith('.epub'))
        .firstOrNull;
    final description = _first(meta['description']);
    var summary = description == null
        ? null
        : (html_parser.parseFragment(description).text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (summary != null && summary.length > 1200) summary = '${summary.substring(0, 1200)}…';
    return book.copyWith(
      epubUrl: epub == null
          ? null
          : 'https://archive.org/download/${book.sourceId}/${Uri.encodeComponent(epub)}',
      summary: summary == null || summary.isEmpty ? null : summary,
      subjects: _list(meta['subject']).take(12).toList(),
    );
  }

  static String? _first(Object? v) => v is List ? (v.isEmpty ? null : '${v.first}') : v as String?;
  static List<String> _list(Object? v) =>
      v == null ? const [] : (v is List ? v.map((e) => '$e').toList() : ['$v']);

  @override
  String rightsNote(Book book) =>
      'From the Internet Archive. Only books published in $latestPublicDomainYear or '
      'earlier are listed, so they are in the public domain in the United States. '
      'The EPUB text was made automatically from page scans and may contain errors. '
      'Copyright terms differ between countries, so check your local laws.';
}
