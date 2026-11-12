import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/shelf.dart';
import '../services/library_service.dart';
import '../services/settings_service.dart';
import '../widgets/library_tile.dart';
import 'collection_actions.dart';

/// The whole library: every saved book, with views (Downloaded, Want to
/// read, Reading, Finished, and the user's shelves), a filter and sorting.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final library = services.library;
    final settings = services.settings;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([library, settings]),
      builder: (context, _) {
        // A deleted shelf falls back to "All".
        var view = settings.libraryView;
        if (view.startsWith('shelf:') && !library.shelves.any((s) => 'shelf:${s.id}' == view)) {
          view = LibraryView.all;
        }
        final entries =
            library.entriesIn(view, sort: settings.librarySort, filter: _filter.text);
        final width = MediaQuery.sizeOf(context).width;
        final pad = width > 900 ? 32.0 : 16.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your library'),
            actions: [
              PopupMenuButton<LibrarySort>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort),
                initialValue: settings.librarySort,
                onSelected: (s) => settings.update((x) => x.librarySort = s),
                itemBuilder: (_) => [
                  for (final s in LibrarySort.values)
                    CheckedPopupMenuItem(
                      value: s,
                      checked: s == settings.librarySort,
                      child: Text(s.label),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
              child: TextField(
                controller: _filter,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Filter by title or author',
                  prefixIcon: const Icon(Icons.filter_list),
                  suffixIcon: _filter.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_filter.clear),
                        ),
                  filled: true,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: pad, vertical: 4),
                  children: [
                    for (final (id, label, icon) in const [
                      (LibraryView.all, 'All', Icons.library_books_outlined),
                      (LibraryView.downloaded, 'Downloaded', Icons.download_done),
                      (LibraryView.wantToRead, 'Want to read', Icons.bookmark_border),
                      (LibraryView.reading, 'Reading', Icons.auto_stories_outlined),
                      (LibraryView.finished, 'Finished', Icons.check_circle_outline),
                    ])
                      _viewChip(settings, view, id, label, icon, library.countIn(id)),
                    if (library.shelves.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: VerticalDivider(width: 1),
                      ),
                    for (final shelf in library.shelves)
                      GestureDetector(
                        onLongPress: () => showShelfMenu(context, shelf),
                        onSecondaryTapUp: (d) =>
                            showShelfMenu(context, shelf, at: d.globalPosition),
                        child: _viewChip(settings, view, LibraryView.shelf(shelf.id), shelf.name,
                            Icons.collections_bookmark_outlined, shelf.bookIds.length),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('New shelf'),
                        onPressed: () async {
                          final name = await showShelfNameDialog(context);
                          if (name == null) return;
                          final shelf = library.createShelf(name);
                          settings.update((s) => s.libraryView = LibraryView.shelf(shelf.id));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (view.startsWith('shelf:'))
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 0),
                child: Text(
                  'Right-click or long-press a shelf to rename or delete it. '
                  'Add books with “Add to shelf” on any book.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            Expanded(
              child: entries.isEmpty
                  ? _empty(theme, view)
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 160,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.5,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          LibraryTile(entry: entries[i], width: double.infinity),
                    ),
            ),
          ]),
        );
      },
    );
  }

  Widget _viewChip(SettingsService settings, String current, String id, String label, IconData icon,
      int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 18),
        showCheckmark: false,
        label: Text('$label  $count'),
        selected: current == id,
        onSelected: (_) => settings.update((s) => s.libraryView = id),
      ),
    );
  }

  Widget _empty(ThemeData theme, String view) {
    final String text;
    if (_filter.text.isNotEmpty) {
      text = 'No books match “${_filter.text}”.';
    } else if (view.startsWith('shelf:')) {
      text = 'This shelf is empty.\nOpen any book and choose “Add to shelf”.';
    } else {
      text = switch (view) {
        LibraryView.downloaded => 'No downloaded books.',
        LibraryView.wantToRead =>
          'Nothing here yet.\nMark books as “Want to read” from the catalog; '
              'they are saved without downloading.',
        LibraryView.reading => 'You are not in the middle of any book.',
        LibraryView.finished => 'Books you finish appear here.',
        _ => 'Your library is empty.',
      };
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.collections_bookmark_outlined,
              size: 44, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
