import 'epub_parser.dart';
import 'title_index.dart';

class SearchHit {
  final int chapter;
  final int block;
  final int start;
  final int end;
  const SearchHit(this.chapter, this.block, this.start, this.end);
}

/// Full-text search inside one book. Case- and accent-insensitive.
class BookSearch {
  final ParsedBook book;
  late final List<List<String>> _folded = [
    for (final c in book.chapters)
      [for (final b in c.blocks) foldSameLength(b.text)],
  ];

  BookSearch(this.book);

  static String normalize(String query) =>
      foldSameLength(query.trim().replaceAll(RegExp(r'\s+'), ' '));

  List<SearchHit> search(String query, {int limit = 2000}) {
    final q = normalize(query);
    if (q.length < 2) return const [];
    final hits = <SearchHit>[];
    for (var c = 0; c < _folded.length; c++) {
      final blocks = _folded[c];
      for (var b = 0; b < blocks.length; b++) {
        for (final (s, e) in _matches(blocks[b], q)) {
          hits.add(SearchHit(c, b, s, e));
          if (hits.length >= limit) return hits;
        }
      }
    }
    return hits;
  }

  /// Match ranges of an already-normalized query in one paragraph.
  List<(int, int)> matchesIn(int chapter, int block, String normalizedQuery) =>
      _matches(_folded[chapter][block], normalizedQuery);

  static List<(int, int)> _matches(String text, String q) {
    final out = <(int, int)>[];
    if (q.isEmpty) return out;
    var i = text.indexOf(q);
    while (i >= 0) {
      out.add((i, i + q.length));
      i = text.indexOf(q, i + q.length);
    }
    return out;
  }

  /// A short excerpt around a hit, with the match position inside it.
  ({String text, int start, int end}) snippet(SearchHit h, {int context = 60}) {
    final t = book.chapters[h.chapter].blocks[h.block].text;
    var from = (h.start - context).clamp(0, t.length);
    var to = (h.end + context).clamp(0, t.length);
    // Snap to word boundaries.
    if (from > 0) {
      final sp = t.indexOf(' ', from);
      if (sp >= 0 && sp < h.start) from = sp + 1;
    }
    if (to < t.length) {
      final sp = t.lastIndexOf(' ', to);
      if (sp > h.end) to = sp;
    }
    final prefix = from > 0 ? '…' : '';
    final suffix = to < t.length ? '…' : '';
    final body = t.substring(from, to).replaceAll('\n', ' ');
    return (
      text: '$prefix$body$suffix',
      start: prefix.length + h.start - from,
      end: prefix.length + h.end - from,
    );
  }
}
