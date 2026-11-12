import 'package:flutter/material.dart';

import '../main.dart';
import '../l10n/l10n_helpers.dart';
import '../models/book.dart';
import '../models/shelf.dart';
import 'book_actions.dart';

/// Asks for a shelf name. Returns null if cancelled.
Future<String?> showShelfNameDialog(
  BuildContext context, {
  String initial = '',
  String? title,
}) {
  final ctrl = TextEditingController(text: initial);
  final t = L10n.of(context);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      void submit() {
        if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
      }

      return AlertDialog(
        title: Text(title ?? t.newShelf),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(hintText: t.shelfNameHint),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L10n.of(context).cancel),
          ),
          FilledButton(
            onPressed: submit,
            child: Text(initial.isEmpty ? t.create : t.rename),
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
          title: Text(L10n.of(context).addToShelf),
          contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          content: SizedBox(
            width: 380,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (shelves.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(L10n.of(context).noShelvesYet),
                  ),
                for (final s in shelves)
                  CheckboxListTile(
                    value: s.contains(book.id),
                    title: Text(s.name),
                    subtitle: Text(
                      L10n.of(context).bookCount(s.bookIds.length),
                    ),
                    onChanged: (v) => library.setOnShelf(s, book, v ?? false),
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(L10n.of(context).newShelfEllipsis),
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
              child: Text(L10n.of(context).done),
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
  final choice = await _menu(context, at, [
    ('rename', Icons.edit_outlined, L10n.of(context).renameShelf),
    ('delete', Icons.delete_outline, L10n.of(context).deleteShelf),
  ]);
  if (!context.mounted) return;
  if (choice == 'rename') {
    final name = await showShelfNameDialog(
      context,
      initial: shelf.name,
      title: L10n.of(context).renameShelf,
    );
    if (name != null) library.renameShelf(shelf, name);
  } else if (choice == 'delete') {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.of(context).deleteShelfQuestion(shelf.name)),
        content: Text(L10n.of(context).deleteShelfBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L10n.of(context).delete),
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
    ('details', Icons.info_outline, L10n.of(context).bookDetails),
    (
      'shelf',
      Icons.collections_bookmark_outlined,
      L10n.of(context).addToShelfEllipsis,
    ),
    if (!finished)
      want
          ? (
              'notwant',
              Icons.bookmark_remove_outlined,
              L10n.of(context).removeFromWantToRead,
            )
          : ('want', Icons.bookmark_add_outlined, L10n.of(context).wantToRead),
    finished
        ? ('unfinished', Icons.replay, L10n.of(context).markNotFinished)
        : (
            'finished',
            Icons.check_circle_outline,
            L10n.of(context).markFinished,
          ),
    if (entry.isDownloaded)
      ('undownload', Icons.cloud_off_outlined, L10n.of(context).removeDownload),
    ('remove', Icons.delete_outline, L10n.of(context).removeFromLibrary),
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
  final t = L10n.of(context);
  await Services.of(context).library.removeDownload(entry.book.id);
  messenger.showSnackBar(
    SnackBar(content: Text(t.downloadRemoved(entry.book.title))),
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
