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
import '../widgets/display_settings.dart';
import '../widgets/library_tile.dart';
import '../l10n/l10n_helpers.dart';
import 'book_actions.dart';
import 'library_screen.dart';

/// Catalog categories (label, Gutenberg subject search).
final _categories = <(String Function(L10n), String)>[
  ((t) => t.catPopular, ''),
  ((t) => t.catFiction, 'fiction'),
  ((t) => t.catMystery, 'detective'),
  ((t) => t.catAdventure, 'adventure'),
  ((t) => t.catScienceFiction, 'science fiction'),
  ((t) => t.catRomance, 'love'),
  ((t) => t.catHorror, 'horror'),
  ((t) => t.catFantasy, 'fantasy'),
  ((t) => t.catChildren, 'juvenile'),
  ((t) => t.catPoetry, 'poetry'),
  ((t) => t.catDrama, 'drama'),
  ((t) => t.catPhilosophy, 'philosophy'),
  ((t) => t.catHistory, 'history'),
  ((t) => t.catScience, 'science'),
  ((t) => t.catBiography, 'biography'),
];

/// Catalog languages, named in their own language ('' = all languages).
const languages = <(String, String)>[
  ('', ''),
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
      setState(
        () => _error = e is TimeoutException
            ? L10n.of(context).catalogTimeout
            : L10n.of(context).catalogOffline,
      );
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  /// Combines Gutenberg's server search (whole words, ranked by popularity)
  /// with the offline title index (any part of a title or author, accents
  /// ignored). Order: popular books whose title/author matches, then other
  /// title matches, then server hits that matched on other metadata.
  Future<CatalogPage> _search(
    AppServices services,
    String query,
    String language,
    String subject,
  ) async {
    final serverFuture = services.catalog
        .fetch(search: query, subject: subject, language: language)
        .then<CatalogPage?>((p) => p, onError: (_) => null);
    await services.titleIndex.load().timeout(
      const Duration(seconds: 20),
      onTimeout: () => null,
    );
    final server = await serverFuture;
    final local = services.titleIndex.search(
      query,
      language: language,
      subject: subject,
    );
    if (server == null && local.isEmpty) {
      throw const CatalogException(ErrorCode.searchFailed);
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
    return CatalogPage([
      for (final b in merged)
        if (seen.add(b.id)) b,
    ], server?.nextUrl);
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
    if (n.metrics.extentAfter < 800 &&
        _nextUrl != null &&
        !_loading &&
        _error == null) {
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
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 10),
            Text(
              'Illuminati',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: L10n.of(context).displayAccessibility,
            icon: const Icon(Icons.tune),
            onPressed: () => showDisplaySettings(context, services.settings),
          ),
          IconButton(
            tooltip: L10n.of(context).about,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              L10n.of(context).discoverFreeBooks,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _LanguageMenu(
                            onChanged: (code) {
                              services.settings.update(
                                (s) => s.catalogLanguage = code,
                              );
                              _reload();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        L10n.of(context).discoverSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
                          hintText: L10n.of(context).searchHint,
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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ScrollConfiguration(
                          // Let mouse users drag the chip row on desktop.
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: PointerDeviceKind.values.toSet(),
                          ),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) => ChoiceChip(
                              label: Text(_categories[i].$1(L10n.of(context))),
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
                child: Column(
                  children: [
                    for (final source in services.sources.extra)
                      if (source.supports(
                        language: services.settings.catalogLanguage,
                        subject: _categories[_category].$2,
                      ))
                        _SourceRow(
                          key: ValueKey('${source.id}-$_rowsEpoch'),
                          source: source,
                          query: _query,
                          language: services.settings.catalogLanguage,
                          subject: _categories[_category].$2,
                          pad: pad,
                        ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 20, pad, 4),
                sliver: SliverToBoxAdapter(
                  child: _RowHeader(
                    title: 'Project Gutenberg',
                    subtitle: L10n.of(context).gutenbergSubtitle,
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
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(L10n.of(context).tryAgain),
              onPressed: () => _books.isEmpty ? _reload() : _load(more: true),
            ),
          ],
        ),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text(L10n.of(context).noBooksFound)),
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
      children: [Text(L10n.of(context).aboutText)],
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _LanguageMenu({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = Services.of(context).settings.catalogLanguage;
    String name((String, String) l) =>
        l.$1.isEmpty ? L10n.of(context).allLanguages : l.$2;
    final label = name(
      languages.firstWhere(
        (l) => l.$1 == current,
        orElse: () => languages.first,
      ),
    );
    return PopupMenuButton<String>(
      tooltip: L10n.of(context).catalogLanguage,
      initialValue: current,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final l in languages)
          PopupMenuItem(value: l.$1, child: Text(name(l))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 18),
            const SizedBox(width: 6),
            Text(label),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

/// The top rows: books already downloaded to this device, plus a way into
/// the whole library (shelves, Want to read, Finished).
class _LibrarySection extends StatelessWidget {
  final double pad;
  const _LibrarySection({required this.pad});

  @override
  Widget build(BuildContext context) {
    final library = Services.of(context).library;
    final theme = Theme.of(context);
    final downloaded = library.downloaded;
    final saved = library.entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                L10n.of(context).yourLibrary,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (saved > 0)
              TextButton.icon(
                icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                ),
                label: Text(L10n.of(context).libraryAndShelves(saved)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (downloaded.isEmpty)
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      saved == 0
                          ? L10n.of(context).libraryEmptyHome
                          : L10n.of(context).noDownloadedSaved(saved),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 244,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: downloaded.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) => LibraryTile(entry: downloaded[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _RowHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _RowHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
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
        : s.search(
            widget.query,
            language: widget.language,
            subject: widget.subject,
          );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardWidth = 136.0;
    const rowHeight = 290.0;

    Widget frame(Widget body) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.pad),
            child: _RowHeader(
              title: widget.source.name,
              subtitle: sourceTagline(L10n.of(context), widget.source.id),
            ),
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );

    return FutureBuilder<List<Book>>(
      future: _books,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return frame(
            SizedBox(
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
            ),
          );
        }
        if (snap.hasError) {
          final e = snap.error;
          // A rate-limited service just sits this round out.
          if (e is SourceException && e.busy) return const SizedBox.shrink();
          return frame(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.pad),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      L10n.of(context).couldNotReach(widget.source.name),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: Text(L10n.of(context).tryAgain),
                  ),
                ],
              ),
            ),
          );
        }
        final books = snap.data ?? const <Book>[];
        if (books.isEmpty) {
          return const SizedBox.shrink(); // nothing to offer here
        }
        return frame(
          SizedBox(
            height: rowHeight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: widget.pad),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) => SizedBox(
                  width: cardWidth,
                  child: _CatalogCard(book: books[i]),
                ),
              ),
            ),
          ),
        );
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                BookCover(book: book),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: ListenableBuilder(
                    listenable: library,
                    builder: (context, _) => _DownloadBadge(book: book),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            authorLine(L10n.of(context), book),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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

    if (library.isDownloaded(book.id)) {
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
            strokeWidth: 2.5,
            value: library.downloads[book.id],
          ),
        ),
      );
    }
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: L10n.of(context).downloadFree,
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        icon: Icon(Icons.download, color: scheme.primary),
        onPressed: () => startDownload(context, book),
      ),
    );
  }
}
