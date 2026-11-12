import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:illuminati/models/book.dart';
import 'package:illuminati/services/catalog_service.dart';
import 'package:illuminati/services/epub_parser.dart';
import 'package:illuminati/services/title_index.dart';

List<int> _buildEpub(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, text) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive);
}

void main() {
  test('parses an EPUB into chapters with titles and formatted blocks', () {
    final bytes = _buildEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': '''<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>''',
      'OEBPS/content.opf': '''<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Test Book</dc:title></metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="c1" href="text/ch%201.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="empty" href="text/cover.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="empty"/><itemref idref="c1"/><itemref idref="c2"/></spine>
</package>''',
      'OEBPS/nav.xhtml': '''<html xmlns="http://www.w3.org/1999/xhtml"><body>
<nav epub:type="toc"><ol><li><a href="text/ch%201.xhtml">Chapter One</a></li></ol></nav>
</body></html>''',
      'OEBPS/text/cover.xhtml': '<html><body><img src="c.jpg" alt="Cover"/></body></html>',
      'OEBPS/text/ch 1.xhtml': '''<html><head><style>p{}</style></head><body>
<h1>I.</h1>
<p>It was a   <i>dark</i> and
   stormy night.</p>
<p>Line one<br/>line two</p>
<hr/>
<blockquote><p>Quoted.</p></blockquote>
</body></html>''',
      'OEBPS/text/ch2.xhtml': '<html><body><h2>The Second</h2><div>Plain div text</div></body></html>',
    });

    final book = parseEpubBytes(bytes);
    expect(book.title, 'Test Book');
    expect(book.chapters.length, 2, reason: 'image-only cover page is skipped');

    final ch1 = book.chapters[0];
    expect(ch1.title, 'Chapter One', reason: 'title comes from the nav document');
    expect(ch1.blocks[0].type, BlockType.h1);

    final p1 = ch1.blocks[1];
    expect(p1.runs.map((r) => r.text).join(), 'It was a dark and stormy night.');
    expect(p1.runs.firstWhere((r) => r.text == 'dark').italic, isTrue);

    expect(ch1.blocks[2].runs.map((r) => r.text).join(), 'Line one\nline two');
    expect(ch1.blocks[3].type, BlockType.separator);
    expect(ch1.blocks[4].type, BlockType.quote);

    final ch2 = book.chapters[1];
    expect(ch2.title, 'The Second', reason: 'falls back to the first heading');
    expect(ch2.blocks.last.runs.single.text, 'Plain div text');
  });

  test('parses Gutenberg OPDS search and detail feeds', () async {
    const search = '''<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<link rel="next" href="/ebooks/search.opds/?query=l.fr&amp;start_index=26"/>
<entry><id>https://www.gutenberg.org/ebooks/subjects.opds</id><title>Subjects</title></entry>
<entry><id>https://www.gutenberg.org/ebooks/4650.opds</id>
<title>Candide, ou l'optimisme (French)</title><content type="text">Voltaire</content></entry>
</feed>''';
    const detail = '''<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:dcterms="http://purl.org/dc/terms/">
<entry><title>Candide</title>
<content type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml">
<p>Summary:
A satire. (This is an automatically generated summary.)</p>
<p>Downloads: 1234</p><p>Category: Text</p></div></content>
<author><name>Voltaire, 1694-1778</name></author>
<category scheme="http://purl.org/dc/terms/LCSH" term="Satire"/>
<dcterms:language>fr</dcterms:language>
<link type="application/epub+zip" rel="http://opds-spec.org/acquisition" href="https://www.gutenberg.org/ebooks/4650.epub.noimages"/>
</entry>
<entry><title>Candide</title>
<link type="application/epub+zip" rel="http://opds-spec.org/acquisition" href="https://www.gutenberg.org/ebooks/4650.epub3.images"/>
</entry></feed>''';
    late Uri requested;
    final catalog = CatalogService(MockClient((req) async {
      requested = req.url;
      return http.Response.bytes(
          utf8.encode(req.url.path.contains('search') ? search : detail), 200);
    }));

    final page = await catalog.fetch(search: 'cand', subject: 'science fiction', language: 'fr');
    expect(requested.queryParameters['query'], 'cand s.science s.fiction l.fr');
    expect(requested.queryParameters['sort_order'], 'downloads');
    expect(page.books.length, 1, reason: 'navigation entries are skipped');
    final b = page.books.single;
    expect(b.id, 4650);
    expect(b.title, "Candide, ou l'optimisme");
    expect(b.authorLine, 'Voltaire');
    expect(page.nextUrl, 'https://www.gutenberg.org/ebooks/search.opds/?query=l.fr&start_index=26');

    final full = await catalog.details(b);
    expect(full.summary, 'A satire.');
    expect(full.downloadCount, 1234);
    expect(full.subjects, ['Satire']);
    expect(full.languages, ['fr']);
    expect(full.authorLine, 'Voltaire');
    expect(full.epubUrl, endsWith('4650.epub3.images'));
    expect(Book.fromJson(full.toJson()).summary, full.summary);
  });

  test('title index finds partial, accent-insensitive title words', () async {
    const csv = 'Text#,Type,Issued,Title,Language,Authors,Subjects,LoCC,Bookshelves\n'
        '135,Text,1994-06-01,Les Misérables,en,"Hugo, Victor, 1802-1885; Hapgood, Isabel F. [Translator]",'
        '"Historical fiction; France -- Fiction",PQ,"Category: Novels"\n'
        '75739,Text,2025-03-29,Los miserables - Tomo 1 (de 2),es,"Hugo, Victor, 1802-1885; J. A. R. [Translator]",'
        'Fiction,PQ,\n'
        '2000,Text,1999-01-01,"Don Quijote",es,"Cervantes Saavedra, Miguel de, 1547-1616",Fiction,PQ,\n'
        '9551,Sound,2003-01-01,Los miserables (audio),es,"Hugo, Victor",,,\n'
        '3000,Text,1999-01-01,"El hombre\nmiserable",es,Anónimo,Poetry,PQ,\n';
    final entries = parseCatalogCsv(csv);
    expect(entries.length, 4, reason: 'sound recordings are skipped');
    expect(entries.first.authors, ['Victor Hugo'], reason: 'translators dropped');
    expect(entries.last.title, 'El hombre miserable', reason: 'newlines in quoted fields');

    final index = TitleIndex.forTesting(entries);
    List<int> ids(String q, {String? lang, String? subject}) =>
        index.search(q, language: lang, subject: subject).map((b) => b.id).toList();

    expect(ids('miserable', lang: 'es'), [3000, 75739],
        reason: 'equal word-start matches are ordered by ebook number');
    expect(ids('misérable', lang: 'es'), [3000, 75739]);
    expect(ids('MISERAB'), [135, 3000, 75739]);
    expect(ids('los mis'), [75739], reason: 'title prefix ranks first');
    expect(ids('hugo miserables'), [135, 75739], reason: 'words may match author');
    expect(ids('quijote cervantes'), [2000]);
    expect(ids('miserable', subject: 'poetry'), [3000]);
    expect(ids('zzz'), isEmpty);
  });
}
