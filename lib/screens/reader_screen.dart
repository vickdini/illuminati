import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../main.dart';
import '../models/annotation.dart';
import '../models/book.dart';
import '../services/book_search.dart';
import '../services/epub_parser.dart';
import '../services/settings_service.dart';
import '../widgets/block_view.dart';
import '../widgets/display_settings.dart';
import 'lookup_sheet.dart';
import 'note_dialog.dart';
import 'reader_panels.dart';

class ReaderScreen extends StatefulWidget {
  final LibraryEntry entry;
  const ReaderScreen({super.key, required this.entry});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  ParsedBook? _book;
  BookAnnotations? _notes;
  BookSearch? _searcher;
  String? _error;

  // Position: chapter, first and last visible paragraph.
  int _chapter = 0;
  int _block = 0;
  int _lastVisible = 0;
  int _initialBlock = 0;
  double _initialAlign = 0;
  bool _chrome = false;

  late List<int> _chapterStart; // character offset where each chapter begins
  int _totalLength = 1;

  var _itemScroll = ItemScrollController();
  var _offsetScroll = ScrollOffsetController();
  var _positions = ItemPositionsListener.create();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _saveTimer;
  double _viewport = 600;
  double _width = 800;
  late final AppServices _services = Services.of(context);
  ModalRoute<dynamic>? _route;

  // Text selection: rebuilding a paragraph (new key) clears its selection.
  int _epochBase = 0;
  final Map<int, int> _blockEpoch = {};
  int? _selBlock;
  bool _selecting = false;

  // Tap-to-turn, detected from raw pointer events so it never competes with
  // text selection gestures. Delayed slightly so a double-click (select word)
  // doesn't also turn the page.
  Offset? _downPos;
  DateTime? _downTime;
  DateTime? _lastUp;
  bool _multiClick = false;
  bool _menuOpen = false;
  Timer? _tapTimer;
  bool _suppressTap = false;

  // In-book search.
  String _searchQuery = '';
  String _searchNorm = '';
  List<SearchHit> _hits = const [];
  int _hitIndex = 0;

  // Reading speed (words per minute), learned as the user reads.
  final Map<int, List<int>> _suffixWords = {};
  late double _wpm;
  DateTime _lastMove = DateTime.now();

  String? get _bookLanguage => widget.entry.book.languages.firstOrNull;

  @override
  void initState() {
    super.initState();
    _chapter = widget.entry.chapter;
    _block = _initialBlock = widget.entry.block;
    _wpm = _services.settings.readingWpm;
    HardwareKeyboard.instance.addHandler(_onKey);
    _open();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  Future<void> _open() async {
    final path = widget.entry.epubPath!; // the reader only opens downloaded books
    try {
      // Parse on a background isolate; pass a top-level function so nothing
      // from this State object is captured and sent across.
      final book = await compute(parseEpubFile, path);
      final notes =
          await BookAnnotations.load(_services.library.annotationsFile(widget.entry.book.id));
      if (!mounted) return;
      notes.reanchor(book);
      notes.addListener(_onNotesChanged);
      // Re-find the reading position by its text if the layout changed.
      final anchor = widget.entry.anchor;
      if (anchor.isNotEmpty) {
        final c = _chapter.clamp(0, book.chapters.length - 1);
        final blocks = book.chapters[c].blocks;
        var ok = false;
        for (var i = _block; i < blocks.length && i < _block + 12; i++) {
          if (blocks[i].text.trim().startsWith(anchor)) {
            ok = true;
            break;
          }
        }
        if (!ok) {
          final found = BookAnnotations.locate(book, c, _block, anchor);
          if (found != null) {
            _chapter = found.$1;
            _block = _initialBlock = found.$2;
          }
        }
      }
      var start = 0;
      _chapterStart = [
        for (final c in book.chapters) (start += c.length) - c.length,
      ];
      _totalLength = start == 0 ? 1 : start;
      setState(() {
        _book = book;
        _notes = notes;
        _chapter = _chapter.clamp(0, book.chapters.length - 1);
        final len = book.chapters[_chapter].blocks.length;
        _block = _initialBlock = _initialBlock.clamp(0, len - 1);
        _lastVisible = _block;
      });
      _positions.itemPositions.addListener(_onPositions);
    } catch (e) {
      if (mounted) setState(() => _error = 'This book could not be opened.\n$e');
    }
  }

  void _onNotesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _saveTimer?.cancel();
    _tapTimer?.cancel();
    _positions.itemPositions.removeListener(_onPositions);
    _notes?.removeListener(_onNotesChanged);
    _saveNow();
    if ((_wpm - _services.settings.readingWpm).abs() > 1) {
      final wpm = _wpm;
      Future.microtask(() => _services.settings.update((s) => s.readingWpm = wpm));
    }
    super.dispose();
  }

  // ---------- Progress & reading speed ----------

  double get _progress {
    final book = _book;
    if (book == null) return widget.entry.progress;
    final blocks = book.chapters[_chapter].blocks;
    var within = 0;
    for (var i = 0; i < _block && i < blocks.length; i++) {
      within += blocks[i].length;
    }
    return ((_chapterStart[_chapter] + within) / _totalLength).clamp(0.0, 1.0);
  }

  /// Words from each paragraph to the end of the chapter.
  List<int> _suffix(int chapter) => _suffixWords.putIfAbsent(chapter, () {
        final blocks = _book!.chapters[chapter].blocks;
        final out = List<int>.filled(blocks.length + 1, 0);
        final word = RegExp(r'\S+');
        for (var i = blocks.length - 1; i >= 0; i--) {
          out[i] = out[i + 1] + word.allMatches(blocks[i].text).length;
        }
        return out;
      });

  String get _timeLeftLabel {
    final s = _suffix(_chapter);
    final end = _book!.sectionEnd(_chapter, _block).clamp(0, s.length - 1);
    final words = s[_block.clamp(0, s.length - 1)] - s[end];
    final mins = words / _wpm;
    if (mins < 1) return 'Less than a minute left in chapter';
    final m = mins.round();
    if (m < 60) return '$m min left in chapter';
    return '${m ~/ 60} h ${m % 60} min left in chapter';
  }

  void _learnSpeed(int from, int to) {
    final now = DateTime.now();
    final minutes = now.difference(_lastMove).inMilliseconds / 60000;
    _lastMove = now;
    if (to <= from) return;
    final s = _suffix(_chapter);
    final words = s[from.clamp(0, s.length - 1)] - s[to.clamp(0, s.length - 1)];
    // Ignore skimming, jumps and long breaks.
    if (words < 20 || minutes < 0.05 || minutes > 10) return;
    final wpm = words / minutes;
    if (wpm < 60 || wpm > 900) return;
    _wpm = (_wpm * 0.85 + wpm * 0.15).clamp(100.0, 700.0);
  }

  bool _finishHandled = false;

  /// Marks the book finished once per session, with an Undo.
  void _markFinished() {
    if (_finishHandled) return;
    _finishHandled = true;
    final book = widget.entry.book;
    final previous = _services.library.entry(book.id)?.status ?? ReadingStatus.none;
    if (previous == ReadingStatus.finished) return;
    _services.library.setStatus(book, ReadingStatus.finished);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('You finished “${book.title}”. It’s now on your Finished list.'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => _services.library.setStatus(book, previous),
      ),
    ));
  }

  void _onPositions() {
    final visible = _positions.itemPositions.value
        .where((p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1);
    if (visible.isEmpty) return;
    var first = visible.first.index, last = first;
    for (final p in visible) {
      if (p.index < first) first = p.index;
      if (p.index > last) last = p.index;
    }
    final blockCount = _book!.chapters[_chapter].blocks.length;
    // "The End" (the item after the last paragraph of the last chapter) is
    // on screen: the book is finished.
    if (_chapter == _book!.chapters.length - 1 && last >= blockCount) _markFinished();
    final block = first.clamp(0, blockCount - 1);
    final lastBlock = last.clamp(0, blockCount - 1);
    if (block != _block || lastBlock != _lastVisible) {
      if (block != _block) _learnSpeed(_block, block);
      setState(() {
        _block = block;
        _lastVisible = lastBlock;
      });
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 1), _saveNow);
    }
  }

  /// A distinctive piece of text at the reading position: the first
  /// substantial paragraph from here on (short lines like captions repeat).
  String _anchorText() {
    final blocks = _book!.chapters[_chapter].blocks;
    String? fallback;
    for (var i = _block; i < blocks.length && i < _block + 12; i++) {
      final t = blocks[i].text.trim();
      if (t.isEmpty) continue;
      fallback ??= t;
      if (t.length >= 40) return t.substring(0, t.length < 80 ? t.length : 80);
    }
    final f = fallback ?? '';
    return f.length > 80 ? f.substring(0, 80) : f;
  }

  void _saveNow() {
    if (_book == null) return;
    _services.library.saveProgress(widget.entry.book.id,
        chapter: _chapter, block: _block, progress: _progress, anchor: _anchorText());
  }

  // ---------- Navigation ----------

  void _goToChapter(int index, {int block = 0, double align = 0}) {
    final book = _book!;
    if (index < 0 || index >= book.chapters.length) return;
    _positions.itemPositions.removeListener(_onPositions);
    setState(() {
      _chapter = index;
      _block = _lastVisible =
          _initialBlock = block.clamp(0, book.chapters[index].blocks.length - 1);
      _initialAlign = align;
      _blockEpoch.clear();
      _selecting = false;
      // Fresh controllers for the new chapter's list.
      _itemScroll = ItemScrollController();
      _offsetScroll = ScrollOffsetController();
      _positions = ItemPositionsListener.create();
    });
    _positions.itemPositions.addListener(_onPositions);
    _lastMove = DateTime.now();
    _saveNow();
  }

  /// Jumps to a paragraph, anywhere in the book.
  void _goTo(int chapter, int block, {double align = 0}) {
    if (chapter == _chapter && _itemScroll.isAttached) {
      _itemScroll.jumpTo(index: block, alignment: align);
      _lastMove = DateTime.now();
    } else {
      _goToChapter(chapter, block: block, align: align);
    }
  }

  bool get _atChapterEnd {
    final last = _book!.chapters[_chapter].blocks.length; // trailing nav item
    return _positions.itemPositions.value
        .any((p) => p.index == last && p.itemTrailingEdge <= 1.01);
  }

  bool get _atChapterStart => _positions.itemPositions.value
      .any((p) => p.index == 0 && p.itemLeadingEdge >= -0.01);

  void _pageForward() {
    if (_atChapterEnd) {
      _goToChapter(_chapter + 1);
    } else {
      _offsetScroll.animateScroll(
          offset: _viewport * 0.9, duration: const Duration(milliseconds: 220));
    }
  }

  void _pageBack() {
    if (_atChapterStart) {
      if (_chapter > 0) {
        _goToChapter(_chapter - 1, block: _book!.chapters[_chapter - 1].blocks.length - 1);
      }
    } else {
      _offsetScroll.animateScroll(
          offset: -_viewport * 0.9, duration: const Duration(milliseconds: 220));
    }
  }

  bool _onKey(KeyEvent event) {
    if (!mounted || _book == null) return false;
    if (!(_route?.isCurrent ?? false)) return false; // a dialog or sheet is open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) return false;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final kb = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final phys = event.physicalKey;

    if (kb.isControlPressed || kb.isMetaPressed) {
      if (key == LogicalKeyboardKey.keyF || phys == PhysicalKeyboardKey.keyF) {
        _openSearch();
        return true;
      }
      if (key == LogicalKeyboardKey.keyB || phys == PhysicalKeyboardKey.keyB) {
        _toggleBookmark();
        return true;
      }
      return false;
    }
    if (kb.isShiftPressed || kb.isAltPressed) return false; // e.g. extend selection

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.space) {
      _pageForward();
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.pageUp) {
      _pageBack();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _offsetScroll.animateScroll(offset: 60, duration: const Duration(milliseconds: 80));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _offsetScroll.animateScroll(offset: -60, duration: const Duration(milliseconds: 80));
    } else if (key == LogicalKeyboardKey.f3 && _hits.isNotEmpty) {
      _stepHit(1);
    } else if (key == LogicalKeyboardKey.escape) {
      if (_selecting) {
        _clearSelection();
      } else if (_searchQuery.isNotEmpty) {
        _closeSearch();
      } else if (_chrome) {
        setState(() => _chrome = false);
      } else {
        Navigator.of(context).maybePop();
      }
    } else {
      return false;
    }
    return true;
  }

  void _pointerDown(PointerDownEvent e) {
    _tapTimer?.cancel();
    _tapTimer = null;
    if (e.kind == PointerDeviceKind.mouse && e.buttons != kPrimaryMouseButton) {
      _downPos = null;
      return;
    }
    final now = DateTime.now();
    // Second click of a double-click (word selection) is never a page turn.
    _multiClick = _lastUp != null && now.difference(_lastUp!) < const Duration(milliseconds: 350);
    _downPos = e.localPosition;
    _downTime = now;
  }

  void _pointerUp(PointerUpEvent e) {
    final down = _downPos;
    _downPos = null;
    _lastUp = DateTime.now();
    if (down == null || _downTime == null || _multiClick) return;
    if ((e.localPosition - down).distance > 12) return; // a drag or selection
    if (DateTime.now().difference(_downTime!) > const Duration(milliseconds: 350)) {
      return; // a long press (selects text on phones)
    }
    final x = e.localPosition.dx;
    _tapTimer = Timer(const Duration(milliseconds: 280), () {
      _tapTimer = null;
      if (!mounted) return;
      if (_suppressTap) {
        _suppressTap = false;
        return;
      }
      _onTap(x);
    });
  }

  void _onTap(double x) {
    if (_menuOpen) {
      _menuOpen = false; // this click only dismissed the selection menu
      return;
    }
    if (_selecting) {
      _clearSelection();
      return;
    }
    if (_chrome) {
      setState(() => _chrome = false);
      return;
    }
    final f = x / _width;
    if (f < 0.3) {
      _pageBack();
    } else if (f > 0.7) {
      _pageForward();
    } else {
      setState(() => _chrome = true);
    }
  }

  // ---------- Selection, highlights, notes ----------

  void _clearSelection() {
    setState(() {
      _epochBase++;
      _blockEpoch.clear();
      _selecting = false;
      _selBlock = null;
    });
  }

  void _onSelection(int block, bool active) {
    if (active) {
      final previous = _selBlock;
      _selBlock = block;
      _selecting = true;
      if (previous != null && previous != block) {
        // Only one selection at a time: reset the paragraph selected before.
        setState(() => _blockEpoch[previous] = (_blockEpoch[previous] ?? 0) + 1);
      }
    } else if (_selBlock == block) {
      _selecting = false;
    }
  }

  SelectionActions _actionsFor(int block) => SelectionActions(
        highlight: (start, end, text) {
          _notes!.addHighlight(Highlight(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            chapter: _chapter,
            block: block,
            start: start,
            end: end,
            text: text,
            color: _services.settings.highlightColor,
            created: DateTime.now(),
          ));
          _clearSelection();
        },
        addNote: (start, end, text) async {
          _clearSelection();
          final r = await showNoteDialog(context,
              quote: text, color: _services.settings.highlightColor);
          if (r == null || r.delete) return;
          _services.settings.update((s) => s.highlightColor = r.color);
          _notes!.addHighlight(Highlight(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            chapter: _chapter,
            block: block,
            start: start,
            end: end,
            text: text,
            color: r.color,
            note: r.note,
            created: DateTime.now(),
          ));
        },
        define: (text) {
          _clearSelection();
          showLookup(context, text, mode: LookupMode.define, bookLanguage: _bookLanguage);
        },
        translate: (text) {
          _clearSelection();
          showLookup(context, text, mode: LookupMode.translate, bookLanguage: _bookLanguage);
        },
        editHighlight: (h) {
          _clearSelection();
          _editHighlight(h);
        },
        removeHighlight: (h) {
          _clearSelection();
          _notes!.removeHighlight(h);
        },
        selectionChanged: (active) => _onSelection(block, active),
        menuChanged: (open) => _menuOpen = open,
      );

  Future<void> _editHighlight(Highlight h) async {
    final r = await showNoteDialog(context,
        quote: h.text, note: h.note, color: h.color, canDelete: true);
    if (r == null) return;
    if (r.delete) {
      _notes!.removeHighlight(h);
    } else {
      h
        ..note = r.note
        ..color = r.color;
      _notes!.changed();
    }
  }

  Bookmark? get _currentBookmark => _notes?.bookmarkIn(_chapter, _block, _lastVisible);

  void _toggleBookmark() {
    final notes = _notes;
    final book = _book;
    if (notes == null || book == null) return;
    final existing = _currentBookmark;
    if (existing != null) {
      notes.removeBookmark(existing);
      return;
    }
    final blocks = book.chapters[_chapter].blocks;
    var snippet = '';
    for (var i = _block; i <= _lastVisible && i < blocks.length; i++) {
      final t = blocks[i].text.trim();
      if (t.isNotEmpty) {
        snippet = t.length > 120 ? '${t.substring(0, 120)}…' : t;
        break;
      }
    }
    notes.toggleBookmark(Bookmark(
        chapter: _chapter, block: _block, snippet: snippet, created: DateTime.now()));
  }

  // ---------- Search ----------

  Future<void> _openSearch() async {
    final book = _book;
    if (book == null) return;
    _searcher ??= BookSearch(book);
    final r = await showModalBottomSheet<(String, List<SearchHit>, int)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (ctx) => _SearchSheet(searcher: _searcher!, initialQuery: _searchQuery),
    );
    if (r == null || !mounted) return;
    setState(() {
      _searchQuery = r.$1;
      _searchNorm = BookSearch.normalize(r.$1);
      _hits = r.$2;
      _hitIndex = r.$3;
      _chrome = false;
    });
    _showHit();
  }

  void _showHit() {
    if (_hits.isEmpty) return;
    final h = _hits[_hitIndex];
    _goTo(h.chapter, h.block, align: 0.25);
  }

  void _stepHit(int delta) {
    if (_hits.isEmpty) return;
    setState(() => _hitIndex = (_hitIndex + delta) % _hits.length);
    _showHit();
  }

  void _closeSearch() => setState(() {
        _searchQuery = '';
        _searchNorm = '';
        _hits = const [];
      });

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final settings = _services.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final rt = settings.readerTheme;
        final dark = rt == ReaderTheme.dark;
        final book = _book;
        final notes = _notes;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: rt.background,
            drawer: book == null || notes == null
                ? null
                : ReaderDrawer(
                    book: book,
                    title: widget.entry.book.title,
                    currentChapter: _chapter,
                    currentBlock: _block,
                    notes: notes,
                    onGo: (c, b) {
                      setState(() => _chrome = false);
                      _goTo(c, b, align: 0.1);
                    },
                    onEditHighlight: _editHighlight,
                  ),
            body: SafeArea(child: _body(settings)),
          ),
        );
      },
    );
  }

  Widget _body(SettingsService settings) {
    final rt = settings.readerTheme;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: rt.foreground)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          ]),
        ),
      );
    }
    final book = _book;
    final notes = _notes;
    if (book == null || notes == null) {
      return Center(child: CircularProgressIndicator(color: rt.foreground));
    }
    final chapter = book.chapters[_chapter];
    final activeHit = _hits.isEmpty ? null : _hits[_hitIndex];
    final faint = rt.foreground.withValues(alpha: 0.55);

    return LayoutBuilder(builder: (context, box) {
      _viewport = box.maxHeight - 40;
      _width = box.maxWidth;
      // Text column: at most the chosen line width, and always leaving the
      // chosen margin on each side.
      final available = box.maxWidth - 2 * settings.margin;
      final column = available < settings.lineWidth ? available : settings.lineWidth;
      final hPad = column < 200 ? settings.margin : (box.maxWidth - column) / 2;
      return Stack(children: [
        Positioned.fill(
          bottom: 28,
          child: Listener(
            onPointerDown: _pointerDown,
            onPointerUp: _pointerUp,
            child: ScrollablePositionedList.builder(
              key: ValueKey(_chapter),
              itemScrollController: _itemScroll,
              scrollOffsetController: _offsetScroll,
              itemPositionsListener: _positions,
              initialScrollIndex: _initialBlock,
              initialAlignment: _initialAlign,
              padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 24),
              itemCount: chapter.blocks.length + 1,
              itemBuilder: (context, i) {
                if (i >= chapter.blocks.length) return _chapterEnd(book, rt);
                final block = chapter.blocks[i];
                final marks = _searchNorm.isEmpty || block.type == BlockType.image
                    ? const <(int, int)>[]
                    : _searcher!.matchesIn(_chapter, i, _searchNorm);
                final bytes = block.image == null ? null : book.images[block.image];
                return BlockView(
                  key: ValueKey('$_epochBase-${_blockEpoch[i] ?? 0}-$i'),
                  block: block,
                  settings: settings,
                  imageBytes: bytes,
                  maxImageHeight: _viewport * 0.8,
                  highlights: notes.inBlock(_chapter, i),
                  searchMarks: marks,
                  activeMark: activeHit != null &&
                          activeHit.chapter == _chapter &&
                          activeHit.block == i
                      ? (activeHit.start, activeHit.end)
                      : null,
                  actions: _actionsFor(i),
                  onImageTap: bytes == null
                      ? null
                      : () {
                          _suppressTap = true;
                          showImageViewer(context, bytes, block.alt);
                        },
                );
              },
            ),
          ),
        ),
        // Bookmark ribbon on the current page.
        if (_currentBookmark != null)
          Positioned(
            top: 0,
            right: hPad - 36 > 8 ? hPad - 36 : 8,
            child: const IgnorePointer(
              child: Icon(Icons.bookmark, color: Color(0xFFD9534F), size: 30),
            ),
          ),
        // Kindle-style footer: time left in chapter and overall progress.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 28,
          child: IgnorePointer(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(children: [
                Expanded(
                  child: Text(_timeLeftLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: faint)),
                ),
                Text('${(_progress * 100).round()}%',
                    style: TextStyle(fontSize: 11, color: faint)),
              ]),
            ),
          ),
        ),
        if (_hits.isNotEmpty || _searchQuery.isNotEmpty) _searchBar(rt),
        _topBar(rt),
        _bottomBar(book, rt),
      ]);
    });
  }

  Widget _searchBar(ReaderTheme rt) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: _chrome ? 64 : 8,
      left: 0,
      right: 0,
      child: Center(
        child: ExcludeFocus(child: Material(
          color: rt == ReaderTheme.dark ? const Color(0xFF2A2A2A) : Colors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Search',
                icon: Icon(Icons.search, color: rt.foreground),
                onPressed: _openSearch,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  _hits.isEmpty
                      ? '“$_searchQuery” · no matches'
                      : '“$_searchQuery” · ${_hitIndex + 1} of ${_hits.length}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: rt.foreground),
                ),
              ),
              IconButton(
                tooltip: 'Previous match',
                icon: Icon(Icons.keyboard_arrow_up, color: rt.foreground),
                onPressed: _hits.isEmpty ? null : () => _stepHit(-1),
              ),
              IconButton(
                tooltip: 'Next match (F3)',
                icon: Icon(Icons.keyboard_arrow_down, color: rt.foreground),
                onPressed: _hits.isEmpty ? null : () => _stepHit(1),
              ),
              IconButton(
                tooltip: 'Close search',
                icon: Icon(Icons.close, color: rt.foreground),
                onPressed: _closeSearch,
              ),
            ]),
          ),
        )),
      ),
    );
  }

  Widget _chapterEnd(ParsedBook book, ReaderTheme rt) {
    final isLast = _chapter == book.chapters.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: ExcludeFocus(child: isLast
            ? Text('— The End —',
                style: TextStyle(color: rt.foreground, fontSize: 16, fontFamily: 'Georgia'))
            : OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: rt.foreground),
                icon: const Icon(Icons.arrow_forward),
                label: Text('Next: ${book.chapters[_chapter + 1].title}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onPressed: () => _goToChapter(_chapter + 1),
              )),
      ),
    );
  }

  Widget _topBar(ReaderTheme rt) {
    final bookmarked = _currentBookmark != null;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: _chrome ? 0 : -72,
      left: 0,
      right: 0,
      // Toolbar controls never take keyboard focus: the reader handles keys
      // itself, and a focused slider would also react to the arrow keys.
      child: ExcludeFocus(child: Material(
        color: rt.background,
        elevation: 3,
        child: SizedBox(
          height: 56,
          child: Row(children: [
            IconButton(
              tooltip: 'Back to library',
              icon: Icon(Icons.arrow_back, color: rt.foreground),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(widget.entry.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: rt.foreground, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              tooltip: 'Search in book (Ctrl+F)',
              icon: Icon(Icons.search, color: rt.foreground),
              onPressed: _openSearch,
            ),
            IconButton(
              tooltip: bookmarked ? 'Remove bookmark (Ctrl+B)' : 'Bookmark this page (Ctrl+B)',
              icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: bookmarked ? const Color(0xFFD9534F) : rt.foreground),
              onPressed: _toggleBookmark,
            ),
            IconButton(
              tooltip: 'Contents, bookmarks & notes',
              icon: Icon(Icons.list, color: rt.foreground),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            IconButton(
              tooltip: 'Display settings',
              icon: Icon(Icons.text_fields, color: rt.foreground),
              onPressed: _showDisplaySettings,
            ),
            const SizedBox(width: 4),
          ]),
        ),
      )),
    );
  }

  /// Real chapters (from the book's table of contents) when available,
  /// otherwise the EPUB's files.
  List<TocEntry> _sections(ParsedBook book) => book.toc.length > 1
      ? book.toc
      : [for (var i = 0; i < book.chapters.length; i++) TocEntry(book.chapters[i].title, i, 0)];

  int _sectionIndex(ParsedBook book) {
    final sections = _sections(book);
    var found = 0;
    for (var i = 0; i < sections.length; i++) {
      final t = sections[i];
      if (t.chapter < _chapter || (t.chapter == _chapter && t.block <= _block)) found = i;
    }
    return found;
  }

  void _goToSection(ParsedBook book, int index) {
    final sections = _sections(book);
    if (index < 0 || index >= sections.length) return;
    final t = sections[index];
    _goTo(t.chapter, t.block);
  }

  Widget _bottomBar(ParsedBook book, ReaderTheme rt) {
    final sections = _sections(book);
    final n = sections.length;
    final current = _sectionIndex(book);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: _chrome ? 0 : -110,
      left: 0,
      right: 0,
      child: ExcludeFocus(child: Material(
        color: rt.background,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              IconButton(
                tooltip: 'Previous chapter',
                icon: Icon(Icons.skip_previous, color: rt.foreground),
                onPressed: current > 0 ? () => _goToSection(book, current - 1) : null,
              ),
              Expanded(
                child: n > 1
                    ? Slider(
                        value: current.toDouble(),
                        max: (n - 1).toDouble(),
                        divisions: n - 1,
                        label: sections[current].title,
                        onChanged: (v) {
                          if (v.round() != current) _goToSection(book, v.round());
                        },
                      )
                    : const SizedBox(),
              ),
              IconButton(
                tooltip: 'Next chapter',
                icon: Icon(Icons.skip_next, color: rt.foreground),
                onPressed: current < n - 1 ? () => _goToSection(book, current + 1) : null,
              ),
            ]),
            Text(
              '${sections[current].title}  ·  Chapter ${current + 1} of $n  ·  '
              '${(_progress * 100).round()}% read',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: rt.foreground.withValues(alpha: 0.7), fontSize: 12),
            ),
          ]),
        ),
      )),
    );
  }

  void _showDisplaySettings() =>
      showDisplaySettings(context, _services.settings, readingWpm: _wpm);
}

/// Search box with live results; returns (query, hits, chosen index).
class _SearchSheet extends StatefulWidget {
  final BookSearch searcher;
  final String initialQuery;
  const _SearchSheet({required this.searcher, required this.initialQuery});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late final _ctrl = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  List<SearchHit> _hits = const [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) _hits = widget.searcher.search(widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _changed(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _hits = widget.searcher.search(q));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = widget.searcher.book;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _changed,
              onSubmitted: (q) {
                final hits = widget.searcher.search(q);
                if (hits.isNotEmpty) Navigator.pop(context, (q, hits, 0));
              },
              decoration: InputDecoration(
                hintText: 'Search in this book',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _ctrl.text.trim().length < 2
                    ? 'Type at least two letters.'
                    : '${_hits.length}${_hits.length >= 2000 ? '+' : ''} matches',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _hits.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final h = _hits[i];
                final s = widget.searcher.snippet(h);
                return ListTile(
                  title: Text.rich(TextSpan(children: [
                    TextSpan(text: s.text.substring(0, s.start)),
                    TextSpan(
                        text: s.text.substring(s.start, s.end),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.3))),
                    TextSpan(text: s.text.substring(s.end)),
                  ])),
                  subtitle: Text(book.chapters[h.chapter].title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(context, (_ctrl.text, _hits, i)),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
