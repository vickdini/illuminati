import 'package:flutter_test/flutter_test.dart';
import 'package:illuminati/models/book.dart';
import 'package:illuminati/sources/internet_archive.dart';
import 'package:illuminati/sources/standard_ebooks.dart';
import 'package:illuminati/sources/wikisource.dart';

void main() {
  test('stable ids are negative, deterministic and distinct per source', () {
    final a = Book.stableId('standardebooks', '/ebooks/jane-austen/emma');
    expect(a, Book.stableId('standardebooks', '/ebooks/jane-austen/emma'));
    expect(a, isNegative);
    expect(a, isNot(Book.stableId('archive', '/ebooks/jane-austen/emma')));
    final b = Book(id: a, title: 'Emma', authors: const [], source: 'standardebooks', sourceId: 'x');
    final round = Book.fromJson(b.toJson());
    expect((round.source, round.sourceId, round.id), ('standardebooks', 'x', a));
    expect(Book.fromJson({'id': 1, 'title': 'T', 'authors': []}).source, 'gutenberg',
        reason: 'library entries saved before sources existed');
    expect(Book.prettyName('Correas, Gonzalo, ca. 1571-1631'), 'Gonzalo Correas');
  });

  test('Standard Ebooks listing and book page', () {
    const listing = '''<ol class="ebooks-list grid">
<li typeof="schema:Book" about="/ebooks/leo-tolstoy/war-and-peace/louise-maude_aylmer-maude">
  <div class="thumbnail-container"><a href="/ebooks/leo-tolstoy/war-and-peace/louise-maude_aylmer-maude">
    <img src="/images/covers/war/cover@2x.jpg" alt=""/></a></div>
  <p><a href="/ebooks/leo-tolstoy/war-and-peace/louise-maude_aylmer-maude"><span property="schema:name">War and Peace</span></a></p>
  <p class="author" typeof="schema:Person"><a href="/ebooks/leo-tolstoy"><span property="schema:name">Leo Tolstoy</span></a></p>
</li></ol>''';
    final b = StandardEbooksSource.parseListing(listing).single;
    expect(b.title, 'War and Peace');
    expect(b.authors, ['Leo Tolstoy']);
    expect(b.coverUrl, 'https://standardebooks.org/images/covers/war/cover@2x.jpg');
    expect(b.epubUrl, endsWith('/leo-tolstoy_war-and-peace_louise-maude-aylmer-maude.epub?source=download'),
        reason: 'underscores inside a path segment become hyphens in the file name');

    const page = '''<section id="description"><h2>Description</h2>
<aside class="donation"><p>We rely on your support.</p></aside>
<p>A <i>sweeping</i> novel.</p><p>Second paragraph.</p></section>
<ul class="tags"><li><a href="/subjects/fiction">Fiction</a></li></ul>
<a href="/ebooks/x/downloads/real-name.epub">epub</a>
<a href="/ebooks/x/downloads/real-name.kepub.epub">kobo</a>''';
    final full = StandardEbooksSource.parseBookPage(b, page);
    expect(full.summary, 'A sweeping novel.\n\nSecond paragraph.', reason: 'donation appeal removed');
    expect(full.subjects, ['Fiction']);
    expect(full.epubUrl, 'https://standardebooks.org/ebooks/x/downloads/real-name.epub?source=download');
  });

  test('Wikisource pages: skips subpages, disambiguation and versions pages', () {
    const json = '''{"query":{"pages":[
 {"title":"Marianela","index":2,"pageprops":{"wikibase_item":"Q1"}},
 {"title":"Los miserables","index":1,"pageprops":{"wikibase_item":"Q2"},
  "categories":[{"title":"Categoría:Versiones"}]},
 {"title":"Don Juan","index":3,"pageprops":{"disambiguation":""}},
 {"title":"Marianela/Capítulo I","index":4},
 {"title":"Nada","missing":true}]}}''';
    final r = WikisourceSource.parsePages('es', json);
    expect(r.books.map((b) => b.title), ['Marianela']);
    final b = r.books.single;
    expect(r.items[b.id], 'Q1');
    expect(b.epubUrl, contains('lang=es&page=Marianela'));
    expect(b.languages, ['es']);
  });

  test('Internet Archive: query, results and metadata', () {
    final q = InternetArchiveSource.buildQuery(
        query: 'Misérables', language: 'fr', subject: '', literature: true);
    expect(q, contains('year:[1500 TO ${DateTime.now().year - 96}]'));
    expect(q, contains('-access-restricted-item:true'));
    expect(q, contains('(title:(miserables) OR creator:(miserables))'),
        reason: 'accents break the archive search');
    expect(q, contains('language:("fre" OR "fra" OR "French")'));
    expect(q, contains('subject:(fiction'));

    final books = InternetArchiveSource.parseSearch('''{"response":{"docs":[
 {"identifier":"quijote01","title":"Don Quijote","creator":["Cervantes Saavedra, Miguel de, 1547-1616","Doré, Gustave"],"downloads":5}]}}''');
    final b = books.single;
    expect(b.authors.first, 'Miguel de Cervantes Saavedra');
    expect(b.coverUrl, 'https://archive.org/services/img/quijote01');

    final full = InternetArchiveSource.parseMetadata(b, '''{"metadata":{"description":"<p>Edición <b>ilustrada</b></p>","subject":["Novela","Spain"]},
 "files":[{"name":"quijote01.pdf"},{"name":"Don Quijote vol 1.epub"}]}''');
    expect(full.summary, 'Edición ilustrada');
    expect(full.subjects, ['Novela', 'Spain']);
    expect(full.epubUrl, 'https://archive.org/download/quijote01/Don%20Quijote%20vol%201.epub');
  });
}
