import 'package:flutter/material.dart';

import '../l10n/l10n_helpers.dart';
import '../main.dart';
import '../models/book.dart';
import '../screens/book_actions.dart';
import '../screens/collection_actions.dart';
import 'book_cover.dart';

/// A book in the library: cover, title and state (progress, finished,
/// want to read, not downloaded). Tap to read; long-press or right-click
/// for the book menu.
class LibraryTile extends StatelessWidget {
  final LibraryEntry entry;
  final double width;
  const LibraryTile({super.key, required this.entry, this.width = 120});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final library = Services.of(context).library;
    final downloading = library.isDownloading(entry.book.id);
    final pct = (entry.progress * 100).round();
    final finished = entry.status == ReadingStatus.finished;

    final Widget status;
    if (finished) {
      status = Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            L10n.of(context).finished,
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary),
          ),
        ],
      );
    } else if (entry.status == ReadingStatus.wantToRead && pct == 0) {
      status = Row(
        children: [
          Icon(Icons.bookmark, size: 14, color: scheme.tertiary),
          const SizedBox(width: 4),
          Text(L10n.of(context).wantToRead, style: theme.textTheme.labelSmall),
        ],
      );
    } else {
      status = Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: entry.progress,
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            pct == 0 ? L10n.of(context).tileNew : '$pct%',
            style: theme.textTheme.labelSmall,
          ),
        ],
      );
    }

    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => openReader(context, entry),
        onLongPress: () => showBookMenu(context, entry),
        onSecondaryTapUp: (d) =>
            showBookMenu(context, entry, at: d.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Saved but not downloaded: a dimmed cover with a cloud.
                  Opacity(
                    opacity: entry.isDownloaded ? 1 : 0.55,
                    child: BookCover(
                      book: entry.book,
                      localPath: entry.coverPath,
                    ),
                  ),
                  if (!entry.isDownloaded)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Tooltip(
                        message: downloading
                            ? L10n.of(context).downloading
                            : L10n.of(context).notDownloaded,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: scheme.surface,
                          child: downloading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: library.downloads[entry.book.id],
                                  ),
                                )
                              : Icon(
                                  Icons.cloud_outlined,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            status,
          ],
        ),
      ),
    );
  }
}
