import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:illuminati/models/annotation.dart';
import 'package:illuminati/services/book_search.dart';
import 'package:illuminati/services/epub_parser.dart';
import 'package:illuminati/services/lookup_service.dart';

List<int> _epub(Map<String, List<int>> files) {
  final a = Archive();
  files.forEach((n, b) => a.addFile(ArchiveFile(n, b.length, b)));
  return ZipEncoder().encode(a);
}

List<int> _t(String s) => utf8.encode(s);

ParsedBook _book() => parseEpubBytes(_epub({
      'META-INF/container.xml': _t('<container><rootfiles><rootfile full-path="OPS/p.opf"/></rootfiles></container>'),
      'OPS/p.opf': _t('''<package><metadata><title>T</title></metadata><manifest>
<item id="a" href="xhtml/a.xhtml" media-type="application/xhtml+xml"/>
<item id="cov" href="xhtml/cover.xhtml" media-type="application/xhtml+xml"/>
</manifest><spine><itemref idref="cov"/><itemref idref="a"/></spine></package>'''),
      'OPS/xhtml/cover.xhtml': _t('<html><body><svg><image xlink:href="../img/cover.jpg"/></svg></body></html>'),
      'OPS/xhtml/a.xhtml': _t('''<html><body><h1>One</h1>
<p>Era el mejor de los tiempos, era el peor de los TIEMPOS.</p>
<p><img src="../img/fig%201.png" alt="A large illustration"/></p>
<p><img src="../img/missing.png" alt="gone"/><img src="../img/d.svg" alt="vector"/></p>
<p>La señora Defarge tejía.</p></body></html>'''),
      'OPS/img/cover.jpg': [0xFF, 0xD8, 0xFF, 1, 2, 3],
      'OPS/img/fig 1.png': [0x89, 0x50, 0x4E, 0x47, 9],
      'OPS/img/d.svg': _t('<svg/>'),
    }));

void main() {
  test('extracts raster images (incl. SVG-wrapped covers) and drops unusable ones', () {
    final book = _book();
    expect(book.chapters.length, 2, reason: 'image-only cover page is kept');
    final cover = book.chapters[0].blocks.single;
    expect(cover.type, BlockType.image);
    expect(cover.image, 'OPS/img/cover.jpg');
    final imgs = book.chapters[1].blocks.where((b) => b.type == BlockType.image).toList();
    expect(imgs.length, 1, reason: 'missing file and SVG image are dropped');
    expect(imgs.single.image, 'OPS/img/fig 1.png');
    expect(imgs.single.alt, 'A large illustration');
    expect(book.images.keys, containsAll(['OPS/img/cover.jpg', 'OPS/img/fig 1.png']));
  });

  test('in-book search is case/accent-insensitive with exact positions', () {
    final book = _book();
    final s = BookSearch(book);
    final hits = s.search('tiempos');
    expect(hits.length, 2);
    final text = book.chapters[hits[1].chapter].blocks[hits[1].block].text;
    expect(text.substring(hits[1].start, hits[1].end), 'TIEMPOS');
    final h = s.search('senora').single;
    expect(book.chapters[h.chapter].blocks[h.block].text.substring(h.start, h.end), 'señora');
    final snip = s.snippet(h);
    expect(snip.text.substring(snip.start, snip.end), 'señora');
    expect(s.search('x'), isEmpty, reason: 'needs two letters');
  });

  test('annotations persist and re-anchor when paragraphs move', () async {
    final book = _book();
    final dir = await Directory.systemTemp.createTemp('notes');
    final file = File('${dir.path}/n.json');
    final notes = BookAnnotations(file);
    // Stored with a stale paragraph number (as if the parser changed).
    notes.addHighlight(Highlight(
        id: '1', chapter: 1, block: 0, start: 3, end: 9, text: 'señora',
        note: 'Madame', created: DateTime(2026)));
    notes.toggleBookmark(Bookmark(
        chapter: 0, block: 0, snippet: 'La señora Defarge', created: DateTime(2026)));
    await notes.saved;

    final loaded = await BookAnnotations.load(file);
    expect(loaded.highlights.single.note, 'Madame');
    loaded.reanchor(book);
    final h = loaded.highlights.single;
    expect(book.chapters[h.chapter].blocks[h.block].text.substring(h.start, h.end), 'señora');
    expect(loaded.bookmarks.single.chapter, 1);
    expect(loaded.toMarkdown('T', book), contains('> señora'));

    // Overlapping highlight replaces the old one.
    loaded.addHighlight(Highlight(
        id: '2', chapter: h.chapter, block: h.block, start: 0, end: 9,
        text: 'La señora', created: DateTime(2026)));
    expect(loaded.highlights.length, 1);
    await loaded.saved;
    await dir.delete(recursive: true);
  });

  test('dictionary and translation responses are parsed', () async {
    final lookup = LookupService(MockClient((req) async {
      if (req.url.host.contains('wiktionary')) {
        if (!req.url.path.endsWith('/desdicha')) return http.Response('', 404);
        return http.Response.bytes(utf8.encode(jsonEncode({
          'en': [{'partOfSpeech': 'Noun', 'language': 'English',
            'definitions': [{'definition': 'english sense'}]}],
          'es': [{'partOfSpeech': 'Noun', 'language': 'Spanish',
            'definitions': [{'definition': '<a href="/wiki/bad_luck">bad luck</a>'}]}],
        })), 200);
      }
      return http.Response.bytes(utf8.encode(jsonEncode({
        'responseData': {'translatedText': 'The best of times', 'match': 0.92},
        'quotaFinished': false,
        'matches': [
          {'translation': 'The best of times', 'created-by': 'MateCat'},
          {'translation': 'It was the best of times.', 'created-by': 'MT!'},
        ],
      })), 200);
    }));

    final defs = await lookup.define('“Desdicha,”', preferLanguage: 'es');
    expect(defs.first.languageCode, 'es', reason: 'book language first');
    expect(defs.first.definitions.single, 'bad luck', reason: 'HTML stripped');
    expect(await lookup.define('zzz'), isEmpty);

    final t = await lookup.translate('Era el mejor de los tiempos', from: 'es', to: 'en');
    expect(t.text, 'It was the best of times.', reason: 'machine translation beats fuzzy memory');

    final bad = LookupService(MockClient((req) async => http.Response.bytes(
        utf8.encode(jsonEncode({
          'responseData': {'translatedText': 'PLEASE SELECT TWO DISTINCT LANGUAGES'},
          'responseDetails': 'PLEASE SELECT TWO DISTINCT LANGUAGES',
          'responseStatus': '403',
          'matches': '',
        })),
        200)));
    await expectLater(bad.translate('hello', from: 'en', to: 'en'),
        throwsA(isA<LookupException>().having((e) => e.message, 'message',
            'Please select two distinct languages')));
  });

  test('table of contents points into files with several chapters', () {
    final book = parseEpubBytes(_epub({
      'META-INF/container.xml':
          _t('<container><rootfiles><rootfile full-path="p.opf"/></rootfiles></container>'),
      'p.opf': _t('<package><manifest>'
          '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'
          '<item id="a" href="a.xhtml" media-type="application/xhtml+xml"/>'
          '</manifest><spine><itemref idref="a"/></spine></package>'),
      'nav.xhtml': _t('<html><body>'
          '<nav epub:type="landmarks"><a href="a.xhtml#c2">Ignore me</a></nav>'
          '<nav epub:type="toc"><ol>'
          '<li><a href="a.xhtml#c1">Chapter I</a></li>'
          '<li><a href="a.xhtml#c2">Chapter II</a></li></ol></nav></body></html>'),
      'a.xhtml': _t('<html><body><p>Preface text.</p>'
          '<div><h2 id="c1">Chapter I.</h2><p>One one one.</p><p>One again.</p></div>'
          '<p>Unfinished <a id="c2"></a></p><h2>Chapter II.</h2><p>Two.</p></body></html>'),
    }));
    expect(book.toc.map((t) => t.title), ['Chapter I', 'Chapter II'],
        reason: 'landmarks are not part of the contents');
    final c1 = book.toc[0], c2 = book.toc[1];
    expect(book.chapters[c1.chapter].blocks[c1.block].text, 'Chapter I.');
    expect(book.chapters[c2.chapter].blocks[c2.block].text, 'Unfinished');
    expect(book.sectionTitle(0, 2), 'Chapter I');
    expect(book.sectionEnd(0, 2), c2.block, reason: 'Chapter I ends where II starts');
    expect(book.sectionTitle(0, 0), book.chapters[0].title, reason: 'before the first entry');
  });
}
