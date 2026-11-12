import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/book.dart';

class CatalogPage {
  final List<Book> books;
  final String? nextUrl;
  const CatalogPage(this.books, this.nextUrl);
}

/// Client for Project Gutenberg's official OPDS catalog, which lists about
/// 75,000 books that are in the public domain in the United States.
///
/// Search syntax (Gutenberg advanced search): plain words match title/author,
/// `s.word` matches a subject, `l.xx` restricts the language.
class CatalogService {
  static const site = 'https://www.gutenberg.org';
  /// Sent with every request. Wikimedia (Wikisource) asks apps to say who
  /// they are and how to reach the maintainers, so it includes the project's
  /// repository.
  static const userAgent = 'Illuminati/1.0 (https://github.com/vickdini/illuminati)';

  final http.Client _client;
  CatalogService([http.Client? client]) : _client = client ?? http.Client();

  static String coverUrlFor(int id) => '$site/cache/epub/$id/pg$id.cover.medium.jpg';
  static String epubUrlFor(int id) => '$site/ebooks/$id.epub3.images';

  Future<XmlDocument> _getXml(Uri uri) async {
    final res = await _client
        .get(uri, headers: {'User-Agent': userAgent})
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw CatalogException('The catalog returned an error (${res.statusCode}).');
    }
    return XmlDocument.parse(utf8.decode(res.bodyBytes, allowMalformed: true));
  }

  /// Fetches a page of books, most downloaded first. Pass [pageUrl] (the
  /// `nextUrl` of a previous page) to continue a listing.
  Future<CatalogPage> fetch({
    String? pageUrl,
    String? search,
    String? subject,
    String? language,
  }) async {
    final Uri uri;
    if (pageUrl != null) {
      uri = Uri.parse(pageUrl);
    } else {
      final terms = <String>[
        if (search != null && search.trim().isNotEmpty)
          // Strip prefix syntax the user did not mean to type.
          search.trim().replaceAll(RegExp(r'[.:]'), ' '),
        if (subject != null && subject.isNotEmpty)
          ...subject.split(' ').map((w) => 's.$w'),
        if (language != null && language.isNotEmpty) 'l.$language',
      ];
      uri = Uri.parse('$site/ebooks/search.opds/').replace(queryParameters: {
        if (terms.isNotEmpty) 'query': terms.join(' '),
        'sort_order': 'downloads',
      });
    }

    final feed = await _getXml(uri);
    final books = <Book>[];
    for (final e in feed.findAllElements('entry')) {
      final id = _ebookId(e.getElement('id')?.innerText);
      if (id == null) continue; // navigation entries such as "Subjects"
      books.add(Book(
        id: id,
        title: _cleanTitle(e.getElement('title')?.innerText ?? 'Untitled'),
        authors: [
          if ((e.getElement('content')?.innerText.trim() ?? '').isNotEmpty)
            e.getElement('content')!.innerText.trim(),
        ],
        coverUrl: coverUrlFor(id),
        epubUrl: epubUrlFor(id),
      ));
    }

    final next = feed
        .findAllElements('link')
        .where((l) => l.getAttribute('rel') == 'next')
        .map((l) => l.getAttribute('href'))
        .whereType<String>()
        .firstOrNull;
    return CatalogPage(books, next == null ? null : Uri.parse(site).resolve(next).toString());
  }

  /// Fetches the full record for one book: summary, subjects, language,
  /// download count and the best EPUB link.
  Future<Book> details(Book book) async {
    final feed = await _getXml(Uri.parse('$site/ebooks/${book.id}.opds'));
    final entry = feed.findAllElements('entry').firstOrNull;
    if (entry == null) return book;

    String? summary;
    var downloads = book.downloadCount;
    String? category;
    for (final p in entry.findAllElements('p', namespace: '*')) {
      final text = p.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.startsWith('Summary:')) {
        summary = text
            .substring(8)
            .replaceAll('(This is an automatically generated summary.)', '')
            .trim();
      } else if (text.startsWith('Downloads:')) {
        downloads = int.tryParse(text.substring(10).trim()) ?? downloads;
      } else if (text.startsWith('Category:')) {
        category = text.substring(9).trim();
      }
    }

    final subjects = entry
        .findElements('category')
        .where((c) => c.getAttribute('scheme')?.endsWith('LCSH') ?? false)
        .map((c) => c.getAttribute('term'))
        .whereType<String>()
        .toList();
    final languages = entry
        .findAllElements('dcterms:language')
        .map((l) => l.innerText.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Download links can sit in a later <entry> than the description.
    final epubs = feed
        .findAllElements('link')
        .where((l) => l.getAttribute('type') == 'application/epub+zip')
        .map((l) => l.getAttribute('href'))
        .whereType<String>()
        .toList();
    String? epub;
    for (final pref in ['.epub3.images', '.epub.images', '.epub.noimages']) {
      epub ??= epubs.where((h) => h.endsWith(pref)).firstOrNull;
    }
    epub ??= epubs.firstOrNull;

    final authors = entry
        .findElements('author')
        .map((a) => Book.prettyName(a.getElement('name')?.innerText ?? ''))
        .where((n) => n.isNotEmpty)
        .toList();

    final String? epubUrl;
    if (epub != null) {
      epubUrl = Uri.parse(site).resolve(epub).toString();
    } else if (category != null && category != 'Text') {
      epubUrl = null; // audio books, music, images: nothing to read
    } else {
      epubUrl = book.epubUrl;
    }

    return Book(
      id: book.id,
      title: book.title,
      authors: authors.isEmpty ? book.authors : authors,
      coverUrl: book.coverUrl,
      epubUrl: epubUrl,
      summary: summary ?? book.summary,
      subjects: subjects,
      languages: languages,
      downloadCount: downloads,
    );
  }

  static int? _ebookId(String? id) {
    if (id == null) return null;
    final m = RegExp(r'/ebooks/(\d+)\.opds$').firstMatch(id.trim());
    return m == null ? null : int.parse(m.group(1)!);
  }

  static const _languageNames =
      'English|French|German|Spanish|Italian|Portuguese|Dutch|Finnish|Latin|Swedish|'
      'Danish|Norwegian|Greek|Russian|Polish|Hungarian|Czech|Chinese|Japanese|Esperanto|'
      'Catalan|Tagalog|Welsh|Irish';

  /// Gutenberg appends the language to non-English titles: "Candide (French)".
  static String _cleanTitle(String t) =>
      t.trim().replaceFirst(RegExp(r'\s*\((' + _languageNames + r')\)$'), '');
}

class CatalogException implements Exception {
  final String message;
  CatalogException(this.message);
  @override
  String toString() => message;
}
