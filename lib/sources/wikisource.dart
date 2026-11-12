import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../services/title_index.dart' show fold;
import 'book_source.dart';

/// Wikisource: a volunteer library of public-domain (and some freely
/// licensed) texts in many languages. Works are listed and searched through
/// the MediaWiki API and turned into EPUBs by WS Export.
///
/// Wikimedia rate-limits anonymous clients, so the popular list is cached and
/// each row costs a single request.
class WikisourceSource extends BookSource {
  final http.Client _client;
  WikisourceSource([http.Client? client]) : _client = client ?? http.Client();

  @override
  String get id => 'wikisource';
  @override
  String get name => 'Wikisource';
  @override
  String get tagline => 'Volunteer-transcribed texts in many languages';

  /// Catalog languages with a Wikisource edition ('' = all -> English).
  static const _languages = {'en', 'es', 'fr', 'de', 'it', 'pt', 'nl', 'fi'};

  /// Each Wikisource names its main page differently.
  static const _mainPages = {
    'Main_Page', 'Portada', 'Accueil', 'Hauptseite', 'Pagina_principale',
    'Página_principal', 'Hoofdpagina', 'Etusivu', 'Wikisource:Portada',
  };

  String _lang(String language) => language.isEmpty ? 'en' : language;

  @override
  bool supports({required String language, required String subject}) =>
      subject.isEmpty && (language.isEmpty || _languages.contains(language));

  final _cache = FeaturedCache();

  /// The most-read works last month (Wikimedia pageview statistics).
  @override
  Future<List<Book>> featured({required String language, required String subject}) =>
      _cache.get(_lang(language), () => _mostRead(_lang(language)));

  Future<List<Book>> _mostRead(String lang) async {
    final now = DateTime.now().toUtc();
    // Last month's statistics are published a day or two into the month.
    final month = DateTime.utc(now.year, now.month - (now.day <= 2 ? 2 : 1));
    final mm = month.month.toString().padLeft(2, '0');
    final res = await sourceGet(
        _client,
        Uri.parse('https://wikimedia.org/api/rest_v1/metrics/pageviews/top/'
            '$lang.wikisource/all-access/${month.year}/$mm/all-days'));
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final articles = ((data['items'] as List).first as Map)['articles'] as List;
    final titles = articles
        .map((a) => (a as Map)['article'] as String)
        .where((t) => !t.contains('/') && !t.contains(':') && !_mainPages.contains(t) && t != '-')
        .take(50) // the API's limit for one titles= request
        .toList();
    // "Most read" includes court cases, laws and letters: keep only works
    // Wikidata knows as literature, with an author.
    return _pages(lang, {'titles': titles.join('|')}, literaryOnly: true);
  }

  /// Search hits are often chapters ("Work/Chapter 3"); each is turned into
  /// its work, so the whole book is offered, once.
  @override
  Future<List<Book>> search(String query,
      {required String language, required String subject}) async {
    final lang = _lang(language);
    final uri = Uri.parse('https://$lang.wikisource.org/w/api.php').replace(queryParameters: {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'list': 'search',
      'srsearch': plainQuery(query),
      'srnamespace': '0',
      'srlimit': '50',
      'srprop': '',
    });
    final res = await sourceGet(_client, uri);
    final hits = ((((jsonDecode(utf8.decode(res.bodyBytes)) as Map)['query'] as Map?)?['search']
            as List?) ??
        const []);
    // A hit inside a work ("Les Misérables/Book 3") stands for the work only
    // if the work's own title matches; otherwise it is an article in an
    // encyclopedia or magazine, which isn't the book the reader wants.
    final words = fold(query).split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    final works = <String>[];
    for (final h in hits) {
      final title = (h as Map)['title'] as String;
      final root = title.split('/').first;
      final isSubpage = root != title;
      if (isSubpage && !words.every(fold(root).contains)) continue;
      final key = root.replaceAll(' ', '_');
      if (!works.contains(key)) works.add(key);
    }
    if (works.isEmpty) return const [];
    return _pages(lang, {'titles': works.take(30).join('|')});
  }

  /// "Versions" pages only list the editions of a work; WS Export would
  /// produce an almost empty book from them.
  static const _versionCategories = [
    'Category:Versions pages',
    'Categoría:Versiones',
    'Catégorie:Éditions multiples',
    'Categoria:Pagine di disambigua',
    'Categoria:!Desambiguação',
  ];

  /// Two API calls: the pages (with their Wikidata items, and whether each
  /// is a disambiguation page), then the works' authors from Wikidata.
  Future<List<Book>> _pages(String lang, Map<String, String> select,
      {bool literaryOnly = false}) async {
    final uri = Uri.parse('https://$lang.wikisource.org/w/api.php').replace(queryParameters: {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'redirects': '1',
      'prop': 'pageprops|categories',
      'ppprop': 'disambiguation|wikibase_item',
      'clcategories': _versionCategories.join('|'),
      ...select,
    });
    final res = await sourceGet(_client, uri);
    final parsed = parsePages(lang, utf8.decode(res.bodyBytes), order: select['titles']?.split('|'));
    if (parsed.items.isEmpty) return literaryOnly ? const [] : parsed.books;
    Map<String, List<String>> authors;
    try {
      authors = await _authors(parsed.items.values.toSet(), lang, literaryOnly: literaryOnly);
    } catch (_) {
      if (literaryOnly) rethrow;
      return parsed.books; // authors are a nicety; never fail a search for them
    }
    return [
      for (final b in parsed.books)
        if (authors[parsed.items[b.id]] != null)
          b.copyWith(authors: authors[parsed.items[b.id]])
        else if (!literaryOnly)
          b
    ];
  }

  /// Author names (Wikidata property P50) for works, in the reader's language.
  /// With [literaryOnly], only items that are literary works (Q7725634), or
  /// editions of one, are returned.
  Future<Map<String, List<String>>> _authors(Set<String> items, String lang,
      {bool literaryOnly = false}) async {
    final values = items.where((q) => RegExp(r'^Q\d+$').hasMatch(q)).map((q) => 'wd:$q').join(' ');
    if (values.isEmpty) return const {};
    const literary = '{ ?item wdt:P31/wdt:P279* wd:Q7725634 } UNION '
        '{ ?item wdt:P629/wdt:P31/wdt:P279* wd:Q7725634 } ';
    final sparql = 'SELECT DISTINCT ?item ?authorLabel WHERE { VALUES ?item { $values } '
        '?item wdt:P50 ?author . ${literaryOnly ? literary : ''}'
        'SERVICE wikibase:label { bd:serviceParam wikibase:language "$lang,en". } }';
    final res = await sourceGet(
        _client,
        Uri.parse('https://query.wikidata.org/sparql')
            .replace(queryParameters: {'query': sparql, 'format': 'json'}));
    final rows = (((jsonDecode(utf8.decode(res.bodyBytes)) as Map)['results'] as Map)['bindings'] as List);
    final out = <String, List<String>>{};
    for (final r in rows) {
      final item = (((r as Map)['item'] as Map)['value'] as String).split('/').last;
      final name = ((r['authorLabel'] as Map?)?['value'] as String?)?.trim();
      if (name == null || name.isEmpty || RegExp(r'^Q\d+$').hasMatch(name)) continue;
      final list = out.putIfAbsent(item, () => []);
      if (!list.contains(name) && list.length < 2) list.add(name);
    }
    return out;
  }

  /// Parses a MediaWiki query response into books (dropping chapter
  /// subpages, disambiguation and missing pages), plus each book's Wikidata
  /// item keyed by book id.
  static ({List<Book> books, Map<int, String> items}) parsePages(String lang, String json,
      {List<String>? order}) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final pages = ((data['query'] as Map?)?['pages'] as List?) ?? const [];
    final list = <(num, Book)>[];
    final items = <int, String>{};
    for (final raw in pages) {
      final p = raw as Map<String, dynamic>;
      final title = p['title'] as String? ?? '';
      if (p['missing'] == true || title.contains('/') || title.isEmpty) continue;
      final props = (p['pageprops'] as Map?) ?? const {};
      if (props.containsKey('disambiguation')) continue;
      if (((p['categories'] as List?) ?? const []).isNotEmpty) continue; // a versions page
      final key = title.replaceAll(' ', '_');
      final id = Book.stableId('wikisource', '$lang:$key');
      if (props['wikibase_item'] is String) items[id] = props['wikibase_item'] as String;
      final rank = order != null ? order.indexOf(key) : (p['index'] as num? ?? 0);
      list.add((
        rank < 0 ? 999 : rank,
        Book(
          id: id,
          source: 'wikisource',
          sourceId: '$lang:$key',
          title: title,
          authors: const [],
          languages: [lang],
          epubUrl: 'https://ws-export.wmcloud.org/?format=epub-3'
              '&lang=$lang&page=${Uri.encodeComponent(key)}',
          webUrl: 'https://$lang.wikisource.org/wiki/${Uri.encodeComponent(key)}',
        ),
      ));
    }
    list.sort((a, b) => a.$1.compareTo(b.$1));
    return (books: [for (final e in list) e.$2], items: items);
  }

  /// Wikisource pages carry no blurb; the listing already has the rest.
  @override
  Future<Book> details(Book book) async => book;

  @override
  String rightsNote(Book book) =>
      'From Wikisource, transcribed by volunteers; the EPUB is generated by WS Export. '
      'Wikisource hosts public-domain texts and some under free licences (such as '
      'CC BY-SA), which allow free reading and sharing. Check your local laws.';
}
