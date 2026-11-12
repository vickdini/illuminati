import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

enum BlockType { h1, h2, h3, paragraph, quote, pre, separator, image }

class TextRun {
  final String text;
  final bool italic;
  final bool bold;
  const TextRun(this.text, {this.italic = false, this.bold = false});
}

class Block {
  final BlockType type;
  final List<TextRun> runs;

  /// For [BlockType.image]: the image's path inside the EPUB, and its alt text.
  final String? image;
  final String? alt;

  const Block(this.type, this.runs, {this.image, this.alt});
  int get length => runs.fold(0, (n, r) => n + r.text.length);
  String get text => runs.map((r) => r.text).join();
}

class Chapter {
  final String title;
  final List<Block> blocks;
  const Chapter(this.title, this.blocks);
  int get length => blocks.fold(0, (n, b) => n + b.length);
}

/// A table-of-contents entry: where a real chapter starts. One EPUB file
/// ([Chapter]) may hold several of these.
class TocEntry {
  final String title;
  final int chapter;
  final int block;
  const TocEntry(this.title, this.chapter, this.block);
}

class ParsedBook {
  final String title;
  final List<Chapter> chapters;

  /// Image bytes keyed by their path inside the EPUB (see [Block.image]).
  final Map<String, Uint8List> images;

  /// The book's own table of contents, in reading order (may be empty).
  final List<TocEntry> toc;

  const ParsedBook(
    this.title,
    this.chapters, [
    this.images = const {},
    this.toc = const [],
  ]);

  /// Index into [toc] of the section containing a position, or -1.
  int sectionAt(int chapter, int block) {
    var found = -1;
    for (var i = 0; i < toc.length; i++) {
      final t = toc[i];
      if (t.chapter < chapter || (t.chapter == chapter && t.block <= block)) {
        found = i;
      } else {
        break;
      }
    }
    return found;
  }

  /// Title of the section containing a position.
  String sectionTitle(int chapter, int block) {
    final i = sectionAt(chapter, block);
    if (i >= 0) return toc[i].title;
    return chapter < chapters.length ? chapters[chapter].title : '';
  }

  /// Block where the section containing a position ends (exclusive), within
  /// the same chapter file.
  int sectionEnd(int chapter, int block) {
    final i = sectionAt(chapter, block);
    for (var j = i + 1; j < toc.length; j++) {
      final t = toc[j];
      if (t.chapter != chapter) break;
      if (t.block > block) return t.block;
    }
    return chapters[chapter].blocks.length;
  }
}

class EpubFormatException implements Exception {
  final String message;
  EpubFormatException(this.message);
  @override
  String toString() => message;
}

/// Reads an EPUB file and flattens it into chapters of text blocks.
/// Pure Dart with no Flutter dependencies, so it can run in a background isolate.
ParsedBook parseEpubFile(String path) =>
    parseEpubBytes(File(path).readAsBytesSync());

ParsedBook parseEpubBytes(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);

  String? readText(String name) {
    final f = archive.findFile(name);
    if (f == null) return null;
    return utf8.decode(f.readBytes() ?? const [], allowMalformed: true);
  }

  final container = readText('META-INF/container.xml');
  if (container == null) throw EpubFormatException('Missing container.xml');
  final opfPath = XmlDocument.parse(container)
      .findAllElements('rootfile')
      .map((e) => e.getAttribute('full-path'))
      .whereType<String>()
      .firstOrNull;
  if (opfPath == null) throw EpubFormatException('Missing package document');

  final opfText = readText(opfPath);
  if (opfText == null) throw EpubFormatException('Missing $opfPath');
  final opf = XmlDocument.parse(opfText);
  final opfDir = p.posix.dirname(opfPath);

  String resolve(String base, String href) {
    final clean = Uri.decodeFull(href.split('#').first);
    final joined = base == '.' ? clean : p.posix.join(base, clean);
    return p.posix.normalize(joined);
  }

  final title =
      opf
          .findAllElements('title', namespace: '*')
          .firstOrNull
          ?.innerText
          .trim() ??
      'Untitled';

  // Manifest: id -> (path, media type, properties)
  final manifest = <String, ({String path, String type, String props})>{};
  for (final item in opf.findAllElements('item', namespace: '*')) {
    final id = item.getAttribute('id');
    final href = item.getAttribute('href');
    if (id == null || href == null) continue;
    manifest[id] = (
      path: resolve(opfDir, href),
      type: item.getAttribute('media-type') ?? '',
      props: item.getAttribute('properties') ?? '',
    );
  }

  // Table of contents in reading order: (file path, fragment id, label).
  final tocRaw = <(String, String?, String)>[];
  void addLabel(String base, String href, String label) {
    label = label.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (label.isEmpty) return;
    final hash = href.indexOf('#');
    final frag = hash >= 0
        ? Uri.decodeComponent(href.substring(hash + 1))
        : null;
    tocRaw.add((
      resolve(base, href),
      frag == null || frag.isEmpty ? null : frag,
      label,
    ));
  }

  final navItem = manifest.values
      .where((m) => m.props.contains('nav'))
      .firstOrNull;
  if (navItem != null) {
    final navHtml = readText(navItem.path);
    if (navHtml != null) {
      final doc = html_parser.parse(navHtml);
      final navDir = p.posix.dirname(navItem.path);
      // Only the main table of contents, not page lists or landmarks.
      final navs = doc.querySelectorAll('nav');
      final toc =
          navs
              .where(
                (n) => n.attributes.entries.any(
                  (e) =>
                      e.key.toString().endsWith('type') &&
                      e.value.contains('toc'),
                ),
              )
              .firstOrNull ??
          navs.firstOrNull;
      for (final a
          in toc?.querySelectorAll('a[href]') ?? const <dom.Element>[]) {
        addLabel(navDir, a.attributes['href']!, a.text);
      }
    }
  }
  final ncxItem = manifest.values
      .where((m) => m.type == 'application/x-dtbncx+xml')
      .firstOrNull;
  if (ncxItem != null && tocRaw.isEmpty) {
    final ncxText = readText(ncxItem.path);
    if (ncxText != null) {
      final ncxDir = p.posix.dirname(ncxItem.path);
      for (final np in XmlDocument.parse(
        ncxText,
      ).findAllElements('navPoint', namespace: '*')) {
        final label = np
            .findElements('navLabel', namespace: '*')
            .firstOrNull
            ?.innerText;
        final src = np
            .findElements('content', namespace: '*')
            .firstOrNull
            ?.getAttribute('src');
        if (label != null && src != null) addLabel(ncxDir, src, label);
      }
    }
  }

  final chapters = <Chapter>[];
  final images = <String, Uint8List>{};
  final chapterOfPath = <String, int>{};
  final anchorsOfPath = <String, Map<String, int>>{};
  for (final ref in opf.findAllElements('itemref', namespace: '*')) {
    if (ref.getAttribute('linear') == 'no') continue;
    final item = manifest[ref.getAttribute('idref')];
    if (item == null || !item.type.contains('html')) continue;
    final content = readText(item.path);
    if (content == null) continue;
    final anchors = <String, int>{};
    final parsed = htmlToBlocks(
      content,
      baseDir: p.posix.dirname(item.path),
      anchors: anchors,
    );
    // Keep only images we can actually load; drop the rest (e.g. SVG).
    bool keep(Block b) {
      if (b.type != BlockType.image) return true;
      final path = b.image!;
      if (images.containsKey(path)) return true;
      if (!_rasterImage.hasMatch(path)) return false;
      final bytes = archive.findFile(path)?.readBytes();
      if (bytes == null || bytes.isEmpty) return false;
      images[path] = Uint8List.fromList(bytes);
      return true;
    }

    final blocks = <Block>[];
    final newIndex = <int>[]; // old block index -> new index
    for (final b in parsed) {
      newIndex.add(blocks.length);
      if (keep(b)) blocks.add(b);
    }
    newIndex.add(blocks.length);
    if (blocks.every((b) => b.type == BlockType.separator)) continue;
    chapterOfPath[item.path] = chapters.length;
    anchorsOfPath[item.path] = {
      for (final e in anchors.entries)
        e.key: newIndex[e.value.clamp(0, newIndex.length - 1)],
    };

    final heading = blocks
        .where((b) => b.type.index <= BlockType.h3.index)
        .map((b) => b.runs.map((r) => r.text).join())
        .firstOrNull;
    final label =
        tocRaw.where((t) => t.$1 == item.path).map((t) => t.$3).firstOrNull ??
        heading ??
        'Section ${chapters.length + 1}';
    chapters.add(Chapter(label, blocks));
  }

  if (chapters.isEmpty) {
    throw EpubFormatException('This book has no readable text.');
  }

  final toc = <TocEntry>[];
  for (final (path, frag, label) in tocRaw) {
    final c = chapterOfPath[path];
    if (c == null) continue;
    final last = chapters[c].blocks.length - 1;
    final block = frag == null
        ? 0
        : (anchorsOfPath[path]![frag] ?? 0).clamp(0, last);
    // Keep reading order; skip entries that would point backwards.
    if (toc.isNotEmpty) {
      final prev = toc.last;
      if (c < prev.chapter || (c == prev.chapter && block < prev.block)) {
        continue;
      }
    }
    toc.add(TocEntry(label, c, block));
  }
  return ParsedBook(title, chapters, images, toc);
}

final _rasterImage = RegExp(
  r'\.(jpe?g|png|gif|webp|bmp)$',
  caseSensitive: false,
);

const _blockTags = {
  'p',
  'div',
  'section',
  'article',
  'header',
  'footer',
  'aside',
  'main',
  'blockquote',
  'pre',
  'li',
  'ul',
  'ol',
  'dl',
  'dt',
  'dd',
  'table',
  'tr',
  'td',
  'th',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'hr',
  'figure',
  'figcaption',
  'body',
  'nav',
  'center',
};
const _skipTags = {'script', 'style', 'head', 'math', 'title'};

/// Converts one XHTML document into a flat list of text and image blocks.
/// Image paths are resolved against [baseDir], the document's folder in the EPUB.
/// Element ids are recorded in [anchors] as the index of the next block.
List<Block> htmlToBlocks(
  String source, {
  String baseDir = '.',
  Map<String, int>? anchors,
}) {
  final doc = html_parser.parse(source);
  final body = doc.body;
  if (body == null) return [];

  final blocks = <Block>[];
  var runs = <TextRun>[];
  var type = BlockType.paragraph;

  void flush() {
    if (runs.isEmpty) return;
    final isPre = type == BlockType.pre;
    // Merge neighbouring runs with the same style so whitespace around a
    // line break is collapsed together with it.
    final merged = <TextRun>[];
    for (final r in runs) {
      final last = merged.isEmpty ? null : merged.last;
      if (last != null && last.italic == r.italic && last.bold == r.bold) {
        merged[merged.length - 1] = TextRun(
          last.text + r.text,
          italic: r.italic,
          bold: r.bold,
        );
      } else {
        merged.add(r);
      }
    }
    // Collapse whitespace and trim the block edges.
    final cleaned = <TextRun>[];
    for (final r in merged) {
      final t = isPre
          ? r.text.replaceAll(_br, '\n')
          : r.text
                .replaceAll(RegExp(r'\s+'), ' ')
                .replaceAll(RegExp(' ?$_br ?'), '\n');
      if (t.isEmpty) continue;
      cleaned.add(TextRun(t, italic: r.italic, bold: r.bold));
    }
    runs = [];
    if (!isPre && cleaned.isNotEmpty) {
      final first = cleaned.first, last = cleaned.last;
      cleaned[0] = TextRun(
        first.text.trimLeft(),
        italic: first.italic,
        bold: first.bold,
      );
      final li = cleaned.length - 1;
      cleaned[li] = TextRun(
        cleaned[li].text.trimRight(),
        italic: last.italic,
        bold: last.bold,
      );
      if (cleaned.every((r) => r.text.trim().isEmpty)) cleaned.clear();
    }
    cleaned.removeWhere((r) => r.text.isEmpty);
    if (cleaned.isNotEmpty) blocks.add(Block(type, cleaned));
  }

  BlockType typeFor(String tag, BlockType inherited) => switch (tag) {
    'h1' => BlockType.h1,
    'h2' => BlockType.h2,
    'h3' || 'h4' || 'h5' || 'h6' => BlockType.h3,
    'blockquote' => BlockType.quote,
    'pre' => BlockType.pre,
    _ => inherited,
  };

  void walk(dom.Node node, BlockType blockType, bool italic, bool bold) {
    if (node is dom.Text) {
      type = blockType;
      runs.add(TextRun(node.text, italic: italic, bold: bold));
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName?.toLowerCase() ?? '';
    if (_skipTags.contains(tag)) return;

    if (tag == 'hr') {
      flush();
      blocks.add(const Block(BlockType.separator, []));
      return;
    }
    if (tag == 'br') {
      runs.add(const TextRun(_br));
      return;
    }
    if (tag == 'img' || tag == 'image') {
      final alt = node.attributes['alt']?.trim() ?? '';
      // Drop-cap images carry their letter as alt text: keep it as text.
      if (tag == 'img' && alt.isNotEmpty && alt.length <= 2) {
        runs.add(TextRun(alt, italic: italic, bold: bold));
        return;
      }
      // Inside <svg>, xlink:href is stored as a namespaced attribute name.
      String? attr(String name) => node.attributes.entries
          .where((e) => e.key.toString() == name)
          .map((e) => e.value)
          .firstOrNull;
      final src = attr('src') ?? attr('xlink:href') ?? attr('href');
      if (src == null || src.startsWith('data:') || src.contains('://')) return;
      flush();
      final clean = Uri.decodeFull(src.split('#').first);
      final path = p.posix.normalize(
        baseDir == '.' ? clean : p.posix.join(baseDir, clean),
      );
      blocks.add(
        Block(
          BlockType.image,
          const [],
          image: path,
          alt: alt.isEmpty ? null : alt,
        ),
      );
      return;
    }
    if (tag == 'svg') {
      // Only pull raster images out of SVG wrappers (common for cover pages).
      for (final img in node.querySelectorAll('image')) {
        walk(img, blockType, italic, bold);
      }
      return;
    }

    final isBlock = _blockTags.contains(tag);
    final childType = isBlock ? typeFor(tag, blockType) : blockType;
    final childItalic = italic || tag == 'i' || tag == 'em' || tag == 'cite';
    final childBold = bold || tag == 'b' || tag == 'strong';

    if (isBlock) flush();
    // Record ids after flushing, so a heading's id points at the heading,
    // and an inline anchor at the paragraph it sits in.
    final id = node.id;
    if (anchors != null && id.isNotEmpty) {
      anchors.putIfAbsent(id, () => blocks.length);
    }
    for (final child in node.nodes) {
      walk(child, childType, childItalic, childBold);
    }
    if (isBlock) {
      type = childType;
      flush();
    }
  }

  walk(body, BlockType.paragraph, false, false);
  flush();
  return blocks;
}

/// Placeholder for `<br>` that survives whitespace collapsing (private-use char).
const _br = '';
