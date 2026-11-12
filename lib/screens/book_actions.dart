import 'package:flutter/material.dart';

import '../main.dart';
import '../l10n/l10n_helpers.dart';
import '../models/book.dart';
import '../widgets/book_cover.dart';
import 'collection_actions.dart';
import 'reader_screen.dart';

/// Opens a downloaded book in the reader; a saved but not downloaded book
/// opens its details page (with the Download button) instead.
void openReader(BuildContext context, LibraryEntry entry) {
  if (!entry.isDownloaded) {
    showBookDetails(context, entry.book);
    return;
  }
  Services.of(context).library.markOpened(entry.book.id);
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ReaderScreen(entry: entry)));
}

Future<void> startDownload(BuildContext context, Book book) async {
  final messenger = ScaffoldMessenger.of(context);
  final t = L10n.of(context);
  try {
    await Services.of(context).library.download(book);
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.addedToLibrary(book.title)),
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.couldNotDownload(book.title, errorText(t, e))),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}

Future<void> confirmRemove(BuildContext context, Book book) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(L10n.of(context).removeFromLibraryQuestion),
      content: Text(L10n.of(context).removeFromLibraryBody(book.title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(L10n.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(L10n.of(context).remove),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await Services.of(context).library.remove(book.id);
  }
}

/// Bottom sheet with a book's details and a Download / Read button.
void showBookDetails(BuildContext context, Book book) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => _BookDetails(book: book, scroll: scroll),
    ),
  );
}

class _BookDetails extends StatefulWidget {
  final Book book;
  final ScrollController scroll;
  const _BookDetails({required this.book, required this.scroll});

  @override
  State<_BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<_BookDetails> {
  late Book book = widget.book;
  bool _loadingDetails = false;

  @override
  void initState() {
    super.initState();
    // Search results only carry title and author; fetch the full record.
    if (book.summary == null && book.subjects.isEmpty) {
      _loadingDetails = true;
      Services.of(context).sources
          .details(book)
          .then((full) {
            if (mounted) setState(() => book = full);
          })
          .catchError((_) {})
          .whenComplete(() {
            if (mounted) setState(() => _loadingDetails = false);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = Services.of(context).library;
    final theme = Theme.of(context);
    final scroll = widget.scroll;
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        final entry = library.entry(book.id);
        final downloading = library.isDownloading(book.id);
        final progress = library.downloads[book.id];

        Widget action;
        if (entry != null && entry.isDownloaded) {
          action = FilledButton.icon(
            icon: const Icon(Icons.menu_book),
            label: Text(
              entry.progress > 0
                  ? L10n.of(context).continueReading
                  : L10n.of(context).readNow,
            ),
            onPressed: () {
              Navigator.pop(context);
              openReader(context, entry);
            },
          );
        } else if (downloading) {
          action = FilledButton.icon(
            icon: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            label: Text(
              progress == null
                  ? L10n.of(context).downloading
                  : L10n.of(
                      context,
                    ).downloadingPercent((progress * 100).round()),
            ),
            onPressed: null,
          );
        } else if (book.epubUrl == null) {
          action = FilledButton(
            onPressed: null,
            child: Text(L10n.of(context).noEbookEdition),
          );
        } else {
          action = FilledButton.icon(
            icon: const Icon(Icons.download),
            label: Text(L10n.of(context).downloadFree),
            onPressed: () => startDownload(context, book),
          );
        }

        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(
                  book: book,
                  localPath: entry?.coverPath,
                  width: 120,
                  height: 180,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        authorLine(L10n.of(context), book),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _Tag(
                            Icons.local_library_outlined,
                            Services.of(context).sources.nameOf(book),
                          ),
                          _Tag(
                            Icons.public,
                            book.source == 'wikisource'
                                ? L10n.of(context).freeToRead
                                : L10n.of(context).publicDomain,
                          ),
                          if (book.languages.isNotEmpty)
                            _Tag(
                              Icons.translate,
                              book.languages.join(', ').toUpperCase(),
                            ),
                          if (book.downloadCount > 0)
                            _Tag(
                              Icons.download_done,
                              L10n.of(
                                context,
                              ).downloadsCount(_compact(book.downloadCount)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      action,
                      if (entry != null &&
                          !downloading &&
                          entry.book.source == 'gutenberg' &&
                          (entry.book.epubUrl ?? '').endsWith('.noimages'))
                        TextButton.icon(
                          icon: const Icon(Icons.image_outlined),
                          label: Text(L10n.of(context).getIllustratedEdition),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final t = L10n.of(context);
                            try {
                              await library.download(entry.book, replace: true);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(t.illustratedDownloaded),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(errorText(t, e))),
                              );
                            }
                          },
                        ),
                      const SizedBox(height: 8),
                      _CollectionButtons(book: book, entry: entry),
                      if (entry != null && entry.isDownloaded && !downloading)
                        TextButton.icon(
                          icon: const Icon(Icons.cloud_off_outlined),
                          label: Text(L10n.of(context).removeDownload),
                          onPressed: () => removeDownload(context, entry),
                        ),
                      if (entry != null && !downloading)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: Text(L10n.of(context).removeFromLibrary),
                          onPressed: () async {
                            await confirmRemove(context, book);
                            if (context.mounted && !library.has(book.id)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_loadingDetails)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: LinearProgressIndicator(),
              ),
            if (book.summary != null) ...[
              const SizedBox(height: 24),
              Text(
                L10n.of(context).aboutThisBook,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                book.summary!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
            if (book.subjects.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                L10n.of(context).subjects,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in book.subjects.take(12))
                    Chip(
                      label: Text(s, style: theme.textTheme.labelSmall),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              rightsNote(L10n.of(context), book),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K';
    return '$n';
  }
}

/// Want to read / Finished / Add to shelf. Works before downloading: the
/// book is saved to the library without its file.
class _CollectionButtons extends StatelessWidget {
  final Book book;
  final LibraryEntry? entry;
  const _CollectionButtons({required this.book, required this.entry});

  @override
  Widget build(BuildContext context) {
    final library = Services.of(context).library;
    final status = entry?.status ?? ReadingStatus.none;
    final shelves = entry == null ? const [] : library.shelvesOf(book.id);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          avatar: Icon(
            status == ReadingStatus.wantToRead
                ? Icons.bookmark
                : Icons.bookmark_border,
            size: 18,
          ),
          showCheckmark: false,
          label: Text(L10n.of(context).wantToRead),
          selected: status == ReadingStatus.wantToRead,
          onSelected: (on) => library.setStatus(
            book,
            on ? ReadingStatus.wantToRead : ReadingStatus.none,
          ),
        ),
        FilterChip(
          avatar: Icon(
            status == ReadingStatus.finished
                ? Icons.check_circle
                : Icons.check_circle_outline,
            size: 18,
          ),
          showCheckmark: false,
          label: Text(L10n.of(context).finished),
          selected: status == ReadingStatus.finished,
          onSelected: (on) => library.setStatus(
            book,
            on ? ReadingStatus.finished : ReadingStatus.none,
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.collections_bookmark_outlined, size: 18),
          label: Text(
            shelves.isEmpty
                ? L10n.of(context).addToShelf
                : shelves.length == 1
                ? L10n.of(context).onShelf(shelves.first.name)
                : L10n.of(context).onShelves(shelves.length),
          ),
          onPressed: () => showShelfPicker(context, book),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tag(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c),
        ),
      ],
    );
  }
}
