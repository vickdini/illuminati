import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/l10n_helpers.dart';

import '../models/annotation.dart';
import '../services/epub_parser.dart';
import '../services/settings_service.dart' show readingSerif;

/// Side panel: table of contents, bookmarks, and highlights & notes.
class ReaderDrawer extends StatelessWidget {
  final ParsedBook book;
  final String title;
  final int currentChapter;
  final int currentBlock;
  final BookAnnotations notes;
  final void Function(int chapter, int block) onGo;
  final void Function(Highlight h) onEditHighlight;

  const ReaderDrawer({
    super.key,
    required this.book,
    required this.title,
    required this.currentChapter,
    required this.currentBlock,
    required this.notes,
    required this.onGo,
    required this.onEditHighlight,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 700;
    return Drawer(
      width: wide ? 400 : null,
      child: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: ListenableBuilder(
            listenable: notes,
            builder: (context, _) => Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: L10n.of(context).contents),
                    Tab(
                      text: L10n.of(
                        context,
                      ).bookmarksCount(notes.bookmarks.length),
                    ),
                    Tab(
                      text: L10n.of(
                        context,
                      ).notesCount(notes.highlights.length),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _contents(context),
                      _bookmarks(context),
                      _highlights(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, int chapter, int block) {
    Navigator.pop(context);
    onGo(chapter, block);
  }

  String _chapterTitle(BuildContext context, int c, int b) =>
      c < book.chapters.length
      ? book.sectionTitle(c, b)
      : L10n.of(context).unknownChapter;

  Widget _contents(BuildContext context) {
    // The book's own table of contents when it has one; otherwise its files.
    final entries = book.toc.length > 1
        ? book.toc
        : [
            for (var i = 0; i < book.chapters.length; i++)
              TocEntry(book.chapters[i].title, i, 0),
          ];
    final current = book.toc.length > 1
        ? book.sectionAt(currentChapter, currentBlock)
        : currentChapter;
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) => ListTile(
        selected: i == current,
        title: Text(
          entries[i].title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _go(context, entries[i].chapter, entries[i].block),
      ),
    );
  }

  Widget _empty(BuildContext context, IconData icon, String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Widget _bookmarks(BuildContext context) {
    if (notes.bookmarks.isEmpty) {
      return _empty(
        context,
        Icons.bookmark_border,
        L10n.of(context).noBookmarks,
      );
    }
    return ListView(
      children: [
        for (final b in notes.bookmarks)
          ListTile(
            leading: const Icon(Icons.bookmark, color: Color(0xFFD9534F)),
            title: Text(
              b.snippet.isEmpty ? L10n.of(context).bookmark : b.snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _chapterTitle(context, b.chapter, b.block),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _go(context, b.chapter, b.block),
            trailing: IconButton(
              tooltip: L10n.of(context).deleteBookmark,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => notes.removeBookmark(b),
            ),
          ),
      ],
    );
  }

  Widget _highlights(BuildContext context) {
    if (notes.highlights.isEmpty) {
      return _empty(
        context,
        Icons.border_color_outlined,
        L10n.of(context).noHighlights,
      );
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.copy_all, size: 18),
            label: Text(L10n.of(context).copyAllMarkdown),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: notes.toMarkdown(title, book)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(L10n.of(context).notesCopied)),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: notes.highlights.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final h = notes.highlights[i];
              return InkWell(
                onTap: () => _go(context, h.chapter, h.block),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 4, height: 48, color: h.color.swatch),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Literata',
                                fontFamilyFallback: readingSerif,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (h.hasNote) ...[
                              const SizedBox(height: 6),
                              Text(h.note, style: theme.textTheme.bodyMedium),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              _chapterTitle(context, h.chapter, h.block),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') onEditHighlight(h);
                          if (v == 'delete') notes.removeHighlight(h);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              h.hasNote
                                  ? L10n.of(context).editNote
                                  : L10n.of(context).addNote,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(L10n.of(context).delete),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
