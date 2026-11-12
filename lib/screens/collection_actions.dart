import 'package:flutter/material.dart';

import '../main.dart';
import '../models/book.dart';
import '../models/shelf.dart';
import 'book_actions.dart';

/// Asks for a shelf name. Returns null if cancelled.
Future<String?> showShelfNameDialog(
  BuildContext context, {
  String initial = '',
  String title = 'New shelf',
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      void submit() {
        if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
      }

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'e.g. Favorites, Philosophy, To read',
          ),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: submit,
            child: Text(initial.isEmpty ? 'Create' : 'Rename'),
          ),
        ],
      );
    },
  );
}

/// Checkbox list of shelves for [book], with "New shelf". Changes apply
/// immediately; the book is added to the library if needed.
Future<void> showShelfPicker(BuildContext context, Book book) {
  final library = Services.of(context).library;
  return showDialog<void>(
    context: context,
    builder: (ctx) => ListenableBuilder(
      listenable: library,
      builder: (ctx, _) {
        final shelves = library.shelves;
        return AlertDialog(
          title: const Text('Add to shelf'),
          contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          content: SizedBox(
            width: 380,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (shelves.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'You have no shelves yet. Create one to group books '
                      'any way you like.',
                    ),
                  ),
                for (final s in shelves)
                  CheckboxListTile(
                    value: s.contains(book.id),
                    title: Text(s.name),
                    subtitle: Text(
                      '${s.bookIds.length} ${s.bookIds.length == 1 ? 'book' : 'books'}',
                    ),
                    onChanged: (v) => library.setOnShelf(s, book, v ?? false),
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New shelf…'),
                  onTap: () async {
                    final name = await showShelfNameDialog(ctx);
                    if (name == null) return;
                    library.setOnShelf(library.createShelf(name), book, true);
                  },
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        );
      },
    ),
  );
}

/// Rename or delete a shelf (its books stay in the library).
Future<void> showShelfMenu(
  BuildContext context,
  Shelf shelf, {
  Offset? at,
}) async {
  final library = Services.of(context).library;
  final choice = await _menu(context, at, const [
    ('rename', Icons.edit_outlined, 'Rename shelf'),
    ('delete', Icons.delete_outline, 'Delete shelf'),
  ]);
  if (!context.mounted) return;
  if (choice == 'rename') {
    final name = await showShelfNameDialog(
      context,
      initial: shelf.name,
      title: 'Rename shelf',
    );
    if (name != null) library.renameShelf(shelf, name);
  } else if (choice == 'delete') {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete “${shelf.name}”?'),
        content: const Text(
          'The shelf is deleted; its books stay in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) library.deleteShelf(shelf);
  }
}

/// The long-press / right-click menu of a book in the library.
Future<void> showBookMenu(
  BuildContext context,
  LibraryEntry entry, {
  Offset? at,
}) async {
  final library = Services.of(context).library;
  final book = entry.book;
  final want = entry.status == ReadingStatus.wantToRead;
  final finished = entry.status == ReadingStatus.finished;
  final choice = await _menu(context, at, [
    ('details', Icons.info_outline, 'Book details'),
    ('shelf', Icons.collections_bookmark_outlined, 'Add to shelf…'),
    if (!finished)
      want
          ? (
              'notwant',
              Icons.bookmark_remove_outlined,
              'Remove from Want to read',
            )
          : ('want', Icons.bookmark_add_outlined, 'Want to read'),
    finished
        ? ('unfinished', Icons.replay, 'Mark as not finished')
        : ('finished', Icons.check_circle_outline, 'Mark as finished'),
    if (entry.isDownloaded)
      ('undownload', Icons.cloud_off_outlined, 'Remove download'),
    ('remove', Icons.delete_outline, 'Remove from library'),
  ]);
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case 'details':
      showBookDetails(context, book);
    case 'shelf':
      showShelfPicker(context, book);
    case 'want':
      library.setStatus(book, ReadingStatus.wantToRead);
    case 'notwant' || 'unfinished':
      library.setStatus(book, ReadingStatus.none);
    case 'finished':
      library.setStatus(book, ReadingStatus.finished);
    case 'undownload':
      await removeDownload(context, entry);
    case 'remove':
      await confirmRemove(context, book);
  }
}

/// Frees the space used by a download; the book stays in the library.
Future<void> removeDownload(BuildContext context, LibraryEntry entry) async {
  final messenger = ScaffoldMessenger.of(context);
  await Services.of(context).library.removeDownload(entry.book.id);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Download removed. “${entry.book.title}” stays in your library '
        'with your notes and place.',
      ),
    ),
  );
}

/// A popup menu at [at] (mouse) or a bottom sheet (touch).
Future<String?> _menu(
  BuildContext context,
  Offset? at,
  List<(String, IconData, String)> items,
) {
  if (at != null) {
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        for (final (value, icon, label) in items)
          PopupMenuItem(
            value: value,
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Text(label),
              ],
            ),
          ),
      ],
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, icon, label) in items)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              onTap: () => Navigator.pop(ctx, value),
            ),
        ],
      ),
    ),
  );
}
