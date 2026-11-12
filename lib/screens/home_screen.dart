import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/book.dart';
import '../services/catalog_service.dart';
import '../services/title_index.dart';
import '../sources/book_source.dart';
import '../widgets/app_logo.dart';
import '../widgets/book_cover.dart';
import 'book_actions.dart';
import 'library_screen.dart';

/// Catalog categories, mapped to Gutenberg subject searches.
const _categories = <(String, String)>[
  ('Popular', ''),
  ('Fiction', 'fiction'),
  ('Mystery', 'detective'),
  ('Adventure', 'adventure'),
  ('Science Fiction', 'science fiction'),
  ('Romance', 'love'),
  ('Horror', 'horror'),
  ('Fantasy', 'fantasy'),
  ('Children', 'juvenile'),
  ('Poetry', 'poetry'),
  ('Drama', 'drama'),
  ('Philosophy', 'philosophy'),
  ('History', 'history'),
  ('Science', 'science'),
  ('Biography', 'biography'),
];

const languages = <(String, String)>[
  ('', 'All languages'),
  ('en', 'English'),
  ('es', 'Español'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
  ('it', 'Italiano'),
  ('pt', 'Português'),
  ('nl', 'Nederlands'),
  ('fi', 'Suomi'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<Book> _books = [];
  String? _nextUrl;
  bool _loading = false;
  String? _error;
  int _category = 0;
  String _query = '';
  int _requestId = 0;

  /// Bumped by pull-to-refresh so the source rows reload too.
  int _rowsEpoch = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_books.isEmpty && !_loading && _error == null) _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _books.clear();
      _nextUrl = null;
      _error = null;
    });
    await _load();
  }

  Future<void> _load({bool more = false}) async {
    final services = Services.of(context);
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final language = services.settings.catalogLanguage;
      final subject = _categories[_category].$2;
      final CatalogPage page;
      if (!more && _query.isNotEmpty) {
        page = await _search(services, _query, language, subject);
      } else {
        page = await services.catalog.fetch(
          pageUrl: more ? _nextUrl : null,
          search: _query,
          subject: subject,
          language: language,
        );
      }
      if (!mounted || id != _requestId) return;
      setState(() {
        final known = _books.map((b) => b.id).toSet();
        _books.addAll(page.books.where((b) => known.add(b.id)));
        _nextUrl = page.nextUrl;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() => _error = e is TimeoutException
          ? 'The catalog is taking too long to respond.'
          : 'Could not load the catalog. Check your internet connection.');
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  /// Combines Gutenberg's server search (whole words, ranked by popularity)
  /// with the offline title index (any part of a title or author, accents
  /// ignored). Order: popular books whose title/author matches, then other
  /// title matches, then server hits that matched on other metadata.
  Future<CatalogPage> _search(
      AppServices services, String query, String language, String subject) async {
    final serverFuture = services.catalog
        .fetch(search: query, subject: subject, language: language)
        .then<CatalogPage?>((p) => p, onError: (_) => null);
    await services.titleIndex
        .load()
        .timeout(const Duration(seconds: 20), onTimeout: () => null);
    final server = await serverFuture;
    final local =
        services.titleIndex.search(query, language: language, subject: subject);
    if (server == null && local.isEmpty) {
      throw CatalogException('Search failed.');
    }

    final words = fold(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    bool matches(Book b) {
      final text = fold('${b.title} ${b.authorLine}');
      return words.every(text.contains);
    }

    final serverBooks = server?.books ?? const <Book>[];
    final merged = [
      ...serverBooks.where(matches),
      ...local,
      ...serverBooks.where((b) => !matches(b)),
    ];
    final seen = <int>{};
    return CatalogPage(
        [for (final b in merged) if (seen.add(b.id)) b], server?.nextUrl);
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (text.trim() == _query) return;
      _query = text.trim();
      _reload();
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 800 && _nextUrl != null && !_loading && _error == null) {
      _load(more: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final pad = width > 900 ? 32.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const AppLogo(size: 32),
          const SizedBox(width: 10),
          Text('Illuminati',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'serif', fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ]),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: RefreshIndicator(
          onRefresh: () {
            setState(() => _rowsEpoch++);
            return _reload();
          },
          child: CustomScrollView(
            slivers: [
              // ---------- Your library ----------
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                sliver: SliverToBoxAdapter(
                  child: ListenableBuilder(
                    listenable: services.library,
                    builder: (context, _) => _LibrarySection(pad: pad),
                  ),
                ),
              ),

              // ---------- Discover ----------
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 28, pad, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text('Discover free books',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        _LanguageMenu(onChanged: (code) {
                          services.settings.update((s) => s.catalogLanguage = code);
                          _reload();
                        }),
                      ]),
                      const SizedBox(height: 4),
                      Text('Classics whose copyright has expired, free to download and keep.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        onSubmitted: (t) {
                          _debounce?.cancel();
                          _query = t.trim();
                          _reload();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by title or author',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchCtrl.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _query = '';
                                    _reload();
                                  },
                                ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ScrollConfiguration(
                          // Let mouse users drag the chip row on desktop.
                          behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: PointerDeviceKind.values.toSet()),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) => ChoiceChip(
                              label: Text(_categories[i].$1),
                              selected: i == _category,
                              onSelected: (_) {
                                if (i == _category) return;
                                setState(() => _category = i);
                                _reload();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ---------- Other free catalogs, one row each ----------
              SliverToBoxAdapter(
                child: Column(children: [
                  for (final source in services.sources.extra)
                    if (source.supports(
                        language: services.settings.catalogLanguage,
                        subject: _categories[_category].$2))
                      _SourceRow(
                        key: ValueKey('${source.id}-$_rowsEpoch'),
                        source: source,
                        query: _query,
                        language: services.settings.catalogLanguage,
                        subject: _categories[_category].$2,
                        pad: pad,
                      ),
                ]),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 20, pad, 4),
                sliver: SliverToBoxAdapter(
                  child: _RowHeader(
                    title: 'Project Gutenberg',
                    subtitle: 'The largest free library: over 75,000 public-domain books',
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 170,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.48,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _CatalogCard(book: _books[i]),
                    childCount: _books.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _footer(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Icon(Icons.cloud_off, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
            onPressed: () => _books.isEmpty ? _reload() : _load(more: true),
          ),
        ]),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No books found. Try another search.')),
      );
    }
    return const SizedBox(height: 32);
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Illuminati',
      applicationVersion: '1.0.0',
      applicationIcon: const AppLogo(size: 48),
      children: const [
        Text('Illuminati lets you find, download and read books that were never '
            'under copyright or whose copyright has expired.\n\n'
            'Books come from Project Gutenberg (gutenberg.org), Standard Ebooks '
            '(standardebooks.org), Wikisource (wikisource.org, as EPUBs made by WS '
            'Export) and the Internet Archive (archive.org). They are in the public '
            'domain in the United States, except some Wikisource texts that are under '
            'free licences. Copyright terms differ between countries, so check your '
            'local laws before downloading.\n\n'
            'Word definitions come from Wiktionary and translations from MyMemory; '
            'the selected text is sent to those services.'),
      ],
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _LanguageMenu({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = Services.of(context).settings.catalogLanguage;
    final label = languages.firstWhere((l) => l.$1 == current,
        orElse: () => languages.first).$2;
    return PopupMenuButton<String>(
      tooltip: 'Catalog language',
      initialValue: current,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final l in languages) PopupMenuItem(value: l.$1, child: Text(l.$2)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.translate, size: 18),
          const SizedBox(width: 6),
          Text(label),
          const Icon(Icons.arrow_drop_down),
        ]),
      ),
    );
  }
}

/// The top rows: books already downloaded to this device.
class _LibrarySection extends StatelessWidget {
  final double pad;
  const _LibrarySection({required this.pad});

  @override
  Widget build(BuildContext context) {
    final library = Services.of(context).library;
    final theme = Theme.of(context);
    final entries = library.entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text('Your library',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (entries.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LibraryScreen())),
              child: Text('See all (${entries.length})'),
            ),
        ]),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Icon(Icons.library_books_outlined,
                    size: 36, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Your library is empty. Books you download from the '
                      'catalog below will appear here, ready to read offline.'),
                ),
              ]),
            ),
          )
        else
          SizedBox(
            height: 244,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) => LibraryTile(entry: entries[i]),
              ),
            ),
          ),
      ],
    );
  }
}

/// A downloaded book: cover, title and reading progress.
class LibraryTile extends StatelessWidget {
  final LibraryEntry entry;
  final double width;
  const LibraryTile({super.key, required this.entry, this.width = 120});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (entry.progress * 100).round();
    void menu(Offset? at) => _showMenu(context, at);

    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => openReader(context, entry),
        onLongPress: () => menu(null),
        onSecondaryTapUp: (d) => menu(d.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: BookCover(book: entry.book, localPath: entry.coverPath),
            ),
            const SizedBox(height: 8),
            Text(entry.book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: entry.progress, minHeight: 3),
                ),
              ),
              const SizedBox(width: 6),
              Text(pct == 0 ? 'New' : '$pct%', style: theme.textTheme.labelSmall),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, Offset? at) async {
    final Future<String?> pick = at != null
        ? showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
            items: const [
              PopupMenuItem(value: 'info', child: Text('Book details')),
              PopupMenuItem(value: 'remove', child: Text('Remove download')),
            ],
          )
        : showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Book details'),
                  onTap: () => Navigator.pop(ctx, 'info'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove download'),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
              ]),
            ),
          );
    final choice = await pick;
    if (!context.mounted) return;
    if (choice == 'info') showBookDetails(context, entry.book);
    if (choice == 'remove') confirmRemove(context, entry.book);
  }
}

class _RowHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _RowHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      Text(subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

/// One extra catalog (Standard Ebooks, Wikisource, ...) as a horizontal row.
/// Shows the source's featured books, or its results for the search box.
class _SourceRow extends StatefulWidget {
  final BookSource source;
  final String query;
  final String language;
  final String subject;
  final double pad;

  const _SourceRow({
    super.key,
    required this.source,
    required this.query,
    required this.language,
    required this.subject,
    required this.pad,
  });

  @override
  State<_SourceRow> createState() => _SourceRowState();
}

class _SourceRowState extends State<_SourceRow> {
  late Future<List<Book>> _books;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SourceRow old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query ||
        old.language != widget.language ||
        old.subject != widget.subject) {
      _load();
    }
  }

  void _load() {
    final s = widget.source;
    _books = widget.query.isEmpty
        ? s.featured(language: widget.language, subject: widget.subject)
        : s.search(widget.query, language: widget.language, subject: widget.subject);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardWidth = 136.0;
    const rowHeight = 290.0;

    Widget frame(Widget body) => Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.pad),
              child: _RowHeader(title: widget.source.name, subtitle: widget.source.tagline),
            ),
            const SizedBox(height: 10),
            body,
          ]),
        );

    return FutureBuilder<List<Book>>(
      future: _books,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return frame(SizedBox(
            height: rowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: widget.pad),
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, __) => Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: cardWidth,
                  height: cardWidth * 1.5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ));
        }
        if (snap.hasError) {
          final e = snap.error;
          // A rate-limited service just sits this round out.
          if (e is SourceException && e.busy) return const SizedBox.shrink();
          return frame(Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.pad),
            child: Row(children: [
              Icon(Icons.cloud_off, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Flexible(child: Text('Couldn’t reach ${widget.source.name}.')),
              TextButton(onPressed: () => setState(_load), child: const Text('Try again')),
            ]),
          ));
        }
        final books = snap.data ?? const <Book>[];
        if (books.isEmpty) return const SizedBox.shrink(); // nothing to offer here
        return frame(SizedBox(
          height: rowHeight,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: widget.pad),
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) =>
                  SizedBox(width: cardWidth, child: _CatalogCard(book: books[i])),
            ),
          ),
        ));
      },
    );
  }
}

/// A book in the free catalog grid.
class _CatalogCard extends StatelessWidget {
  final Book book;
  const _CatalogCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final library = Services.of(context).library;
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showBookDetails(context, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(fit: StackFit.expand, children: [
              BookCover(book: book),
              Positioned(
                right: 6,
                bottom: 6,
                child: ListenableBuilder(
                  listenable: library,
                  builder: (context, _) => _DownloadBadge(book: book),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text(book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(book.authorLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DownloadBadge extends StatelessWidget {
  final Book book;
  const _DownloadBadge({required this.book});

  @override
  Widget build(BuildContext context) {
    final library = Services.of(context).library;
    final scheme = Theme.of(context).colorScheme;

    if (library.has(book.id)) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: scheme.primary,
        child: Icon(Icons.check, size: 18, color: scheme.onPrimary),
      );
    }
    if (library.isDownloading(book.id)) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: scheme.surface,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, value: library.downloads[book.id]),
        ),
      );
    }
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: 'Download free',
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        icon: Icon(Icons.download, color: scheme.primary),
        onPressed: () => startDownload(context, book),
      ),
    );
  }
}
