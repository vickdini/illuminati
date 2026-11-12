import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/epub_parser.dart';

enum HighlightColor { yellow, green, blue, pink }

extension HighlightColors on HighlightColor {
  Color get swatch => switch (this) {
        HighlightColor.yellow => const Color(0xFFF5D547),
        HighlightColor.green => const Color(0xFF8FD47E),
        HighlightColor.blue => const Color(0xFF7DB8F5),
        HighlightColor.pink => const Color(0xFFF590BC),
      };

  /// Background behind highlighted text; softer on dark pages.
  Color background(bool dark) => swatch.withValues(alpha: dark ? 0.38 : 0.55);
}

/// A position in a parsed book: chapter, paragraph (block), character range.
/// [text] is the quoted text, used to re-find the spot if block numbering
/// ever changes (e.g. after a parser update).
class Highlight {
  final String id;
  int chapter;
  int block;
  int start;
  int end;
  final String text;
  HighlightColor color;
  String note;
  final DateTime created;

  Highlight({
    required this.id,
    required this.chapter,
    required this.block,
    required this.start,
    required this.end,
    required this.text,
    this.color = HighlightColor.yellow,
    this.note = '',
    required this.created,
  });

  bool get hasNote => note.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter': chapter,
        'block': block,
        'start': start,
        'end': end,
        'text': text,
        'color': color.name,
        'note': note,
        'created': created.toIso8601String(),
      };

  factory Highlight.fromJson(Map<String, dynamic> j) => Highlight(
        id: j['id'] as String,
        chapter: j['chapter'] as int,
        block: j['block'] as int,
        start: j['start'] as int,
        end: j['end'] as int,
        text: j['text'] as String,
        color: HighlightColor.values.firstWhere((c) => c.name == j['color'],
            orElse: () => HighlightColor.yellow),
        note: j['note'] as String? ?? '',
        created: DateTime.parse(j['created'] as String),
      );
}

class Bookmark {
  int chapter;
  int block;

  /// Opening words of the bookmarked paragraph, for display and re-anchoring.
  final String snippet;
  final DateTime created;

  Bookmark({
    required this.chapter,
    required this.block,
    required this.snippet,
    required this.created,
  });

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        'block': block,
        'snippet': snippet,
        'created': created.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        chapter: j['chapter'] as int,
        block: j['block'] as int,
        snippet: j['snippet'] as String? ?? '',
        created: DateTime.parse(j['created'] as String),
      );
}

/// Highlights, notes and bookmarks for one book, saved as JSON next to it.
class BookAnnotations extends ChangeNotifier {
  final File file;
  final List<Highlight> highlights = [];
  final List<Bookmark> bookmarks = [];

  BookAnnotations(this.file);

  static Future<BookAnnotations> load(File file) async {
    final a = BookAnnotations(file);
    if (await file.exists()) {
      try {
        final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        a.highlights.addAll(((j['highlights'] as List?) ?? [])
            .map((e) => Highlight.fromJson((e as Map).cast<String, dynamic>())));
        a.bookmarks.addAll(((j['bookmarks'] as List?) ?? [])
            .map((e) => Bookmark.fromJson((e as Map).cast<String, dynamic>())));
      } catch (e) {
        debugPrint('Could not read annotations: $e');
      }
    }
    return a;
  }

  Future<void> _save() async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode({
      'highlights': highlights.map((h) => h.toJson()).toList(),
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
    }));
    await tmp.rename(file.path);
  }

  Future<void> _saving = Future.value();

  /// Completes when every change made so far is on disk.
  Future<void> get saved => _saving;

  void changed() {
    _sort();
    notifyListeners();
    // Queue saves so two quick edits never write the temp file at once.
    _saving = _saving.then((_) => _save()).catchError((Object e) {
      debugPrint('Could not save annotations: $e');
    });
  }

  void _sort() {
    int byPos(int c1, int b1, int s1, int c2, int b2, int s2) =>
        c1 != c2 ? c1 - c2 : (b1 != b2 ? b1 - b2 : s1 - s2);
    highlights.sort((a, b) => byPos(a.chapter, a.block, a.start, b.chapter, b.block, b.start));
    bookmarks.sort((a, b) => byPos(a.chapter, a.block, 0, b.chapter, b.block, 0));
  }

  void addHighlight(Highlight h) {
    // Merge with highlights it overlaps in the same paragraph.
    highlights.removeWhere((o) =>
        o.chapter == h.chapter && o.block == h.block && o.start < h.end && h.start < o.end);
    highlights.add(h);
    changed();
  }

  void removeHighlight(Highlight h) {
    highlights.remove(h);
    changed();
  }

  List<Highlight> inBlock(int chapter, int block) => [
        for (final h in highlights)
          if (h.chapter == chapter && h.block == block) h
      ];

  Bookmark? bookmarkIn(int chapter, int firstBlock, int lastBlock) {
    for (final b in bookmarks) {
      if (b.chapter == chapter && b.block >= firstBlock && b.block <= lastBlock) return b;
    }
    return null;
  }

  void toggleBookmark(Bookmark b) {
    final existing = bookmarks
        .where((o) => o.chapter == b.chapter && o.block == b.block)
        .firstOrNull;
    if (existing != null) {
      bookmarks.remove(existing);
    } else {
      bookmarks.add(b);
    }
    changed();
  }

  void removeBookmark(Bookmark b) {
    bookmarks.remove(b);
    changed();
  }

  /// Re-finds highlights and bookmarks whose stored position no longer
  /// matches the book's text (e.g. after a parser change).
  void reanchor(ParsedBook book) {
    var moved = false;
    for (final h in highlights) {
      if (_matches(book, h.chapter, h.block, h.start, h.text)) continue;
      final found = locate(book, h.chapter, h.block, h.text);
      if (found != null) {
        h
          ..chapter = found.$1
          ..block = found.$2
          ..start = found.$3
          ..end = found.$3 + h.text.length;
        moved = true;
      }
    }
    for (final b in bookmarks) {
      if (b.snippet.isEmpty || _matches(book, b.chapter, b.block, 0, b.snippet)) continue;
      final found = locate(book, b.chapter, b.block, b.snippet);
      if (found != null) {
        b
          ..chapter = found.$1
          ..block = found.$2;
        moved = true;
      }
    }
    if (moved) changed();
  }

  static bool _matches(ParsedBook book, int c, int b, int start, String text) {
    if (c >= book.chapters.length) return false;
    final blocks = book.chapters[c].blocks;
    if (b >= blocks.length) return false;
    final t = blocks[b].text;
    return start + text.length <= t.length && t.substring(start, start + text.length) == text;
  }

  /// Finds [text] in the book: in [chapter] outward from [block] first, then
  /// in the other chapters. Returns (chapter, block, offset).
  static (int, int, int)? locate(ParsedBook book, int chapter, int block, String text) {
    final order = [
      if (chapter < book.chapters.length) chapter,
      for (var c = 0; c < book.chapters.length; c++)
        if (c != chapter) c,
    ];
    for (final c in order) {
      final blocks = book.chapters[c].blocks;
      final idx = List.generate(blocks.length, (i) => i)
        ..sort((a, b) => (a - block).abs() - (b - block).abs());
      for (final i in idx) {
        final at = blocks[i].text.indexOf(text);
        if (at >= 0) return (c, i, at);
      }
    }
    return null;
  }

  /// All highlights and notes as Markdown, for sharing or backup.
  String toMarkdown(String title, ParsedBook book) {
    final out = StringBuffer('# $title — notes\n\n');
    String? lastSection;
    for (final h in highlights) {
      if (h.chapter < book.chapters.length) {
        final section = book.sectionTitle(h.chapter, h.block);
        if (section != lastSection) {
          out.writeln('## $section\n');
          lastSection = section;
        }
      }
      out.writeln('> ${h.text.replaceAll('\n', '\n> ')}\n');
      if (h.hasNote) out.writeln('${h.note}\n');
    }
    return out.toString();
  }
}
