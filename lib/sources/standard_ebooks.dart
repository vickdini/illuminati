import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/book.dart';
import 'book_source.dart';

/// Standard Ebooks (standardebooks.org): carefully proofread and typeset
/// public-domain books, in English. Their OPDS feeds are for paying patrons,
/// so this reads the public website's listing and book pages instead.
class StandardEbooksSource extends BookSource {
  static const site = 'https://standardebooks.org';

  final http.Client _client;
  StandardEbooksSource([http.Client? client])
    : _client = client ?? http.Client();

  @override
  String get id => 'standardebooks';
  @override
  String get name => 'Standard Ebooks';

  /// Home-screen categories (Gutenberg subjects) -> Standard Ebooks subjects.
  static const _subjects = {
    'fiction': 'fiction',
    'detective': 'mystery',
    'adventure': 'adventure',
    'science fiction': 'science-fiction',
    'horror': 'horror',
    'fantasy': 'fantasy',
    'juvenile': 'childrens',
    'poetry': 'poetry',
    'drama': 'drama',
    'philosophy': 'philosophy',
    'biography': 'biography',
  };

  @override
  bool supports({required String language, required String subject}) =>
      (language.isEmpty || language == 'en') &&
      (subject.isEmpty || _subjects.containsKey(subject));

  final _cache = FeaturedCache();

  @override
  Future<List<Book>> featured({
    required String language,
    required String subject,
  }) => _cache.get(
    subject,
    () => _list({'sort': 'popularity', 'per-page': '24', ..._tag(subject)}),
  );

  @override
  Future<List<Book>> search(
    String query, {
    required String language,
    required String subject,
  }) => _list({'query': plainQuery(query), 'per-page': '24', ..._tag(subject)});

  Map<String, String> _tag(String subject) =>
      _subjects[subject] == null ? const {} : {'tags[]': _subjects[subject]!};

  Future<List<Book>> _list(Map<String, String> params) async {
    final uri = Uri.parse('$site/ebooks').replace(queryParameters: params);
    final res = await sourceGet(_client, uri);
    return parseListing(utf8.decode(res.bodyBytes, allowMalformed: true));
  }

  /// Parses the ebook grid of a listing or search page.
  static List<Book> parseListing(String htmlText) {
    final doc = html_parser.parse(htmlText);
    final books = <Book>[];
    for (final li in doc.querySelectorAll('li[typeof="schema:Book"]')) {
      final path = li.attributes['about'];
      if (path == null || !path.startsWith('/ebooks/')) continue;
      final title = li
          .querySelectorAll('p')
          .where((p) => !p.classes.contains('author'))
          .map((p) => p.querySelector('[property="schema:name"]')?.text.trim())
          .whereType<String>()
          .firstOrNull;
      if (title == null || title.isEmpty) continue;
      final authors = li
          .querySelectorAll('p.author [property="schema:name"]')
          .map((e) => e.text.trim())
          .where((a) => a.isNotEmpty)
          .toList();
      final img = li.querySelector('img')?.attributes['src'];
      books.add(
        Book(
          id: Book.stableId('standardebooks', path),
          source: 'standardebooks',
          sourceId: path,
          title: title,
          authors: authors,
          languages: const ['en'],
          coverUrl: img == null ? null : _absolute(img),
          epubUrl: _guessEpub(path),
          webUrl: '$site$path',
        ),
      );
    }
    return books;
  }

  /// "/ebooks/jane-austen/emma" -> ".../downloads/jane-austen_emma.epub".
  /// The exact name is read from the book page in [details]; this guess is
  /// right for most books.
  static String _guessEpub(String path) {
    final parts = path
        .substring('/ebooks/'.length)
        .split('/')
        .map((s) => s.replaceAll('_', '-'));
    return '$site$path/downloads/${parts.join('_')}.epub?source=download';
  }

  static String _absolute(String url) =>
      url.startsWith('http') ? url : '$site$url';

  @override
  Future<Book> details(Book book) async {
    final path = book.sourceId;
    if (path == null) return book;
    final res = await sourceGet(_client, Uri.parse('$site$path'));
    return parseBookPage(
      book,
      utf8.decode(res.bodyBytes, allowMalformed: true),
    );
  }

  static Book parseBookPage(Book book, String htmlText) {
    final doc = html_parser.parse(htmlText);

    // The compatible EPUB (not the Kobo or "advanced" variants). Without
    // ?source=download the site shows a thank-you page instead of the file.
    final epub = doc
        .querySelectorAll('a[href]')
        .map((a) => a.attributes['href']!)
        .where(
          (h) =>
              h.endsWith('.epub') &&
              !h.endsWith('.kepub.epub') &&
              !h.contains('_advanced'),
        )
        .firstOrNull;

    String? summary;
    final description = doc.querySelector('section#description');
    if (description != null) {
      description
          .querySelectorAll('aside')
          .forEach((a) => a.remove()); // donation appeal
      final paragraphs = description
          .querySelectorAll('p')
          .map((p) => p.text.replaceAll(RegExp(r'\s+'), ' ').trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (paragraphs.isNotEmpty) summary = paragraphs.take(3).join('\n\n');
    }
    final subjects = doc
        .querySelectorAll('ul.tags a')
        .map((dom.Element a) => a.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return book.copyWith(
      epubUrl: epub == null ? null : '${_absolute(epub)}?source=download',
      summary: summary,
      subjects: subjects.isEmpty ? null : subjects,
    );
  }
}
