import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/l10n_helpers.dart';

import '../models/annotation.dart';
import '../services/epub_parser.dart';
import '../services/settings_service.dart';

/// What the reader does with a text selection.
class SelectionActions {
  final void Function(int start, int end, String text) highlight;
  final void Function(int start, int end, String text) addNote;
  final void Function(String text) define;
  final void Function(String text) translate;
  final void Function(Highlight h) editHighlight;
  final void Function(Highlight h) removeHighlight;

  /// Called whenever the user selects (true) or the selection collapses (false).
  final void Function(bool active) selectionChanged;

  /// Called when the selection menu opens or closes.
  final void Function(bool open) menuChanged;

  const SelectionActions({
    required this.highlight,
    required this.addNote,
    required this.define,
    required this.translate,
    required this.editHighlight,
    required this.removeHighlight,
    required this.selectionChanged,
    required this.menuChanged,
  });
}

/// One paragraph, heading or image of a book.
class BlockView extends StatelessWidget {
  final Block block;
  final SettingsService settings;
  final Uint8List? imageBytes;
  final double maxImageHeight;
  final List<Highlight> highlights;
  final List<(int, int)> searchMarks;
  final (int, int)? activeMark;
  final SelectionActions actions;
  final VoidCallback? onImageTap;

  const BlockView({
    super.key,
    required this.block,
    required this.settings,
    required this.actions,
    this.imageBytes,
    this.maxImageHeight = 600,
    this.highlights = const [],
    this.searchMarks = const [],
    this.activeMark,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final rt = settings.readerTheme;
    final size = settings.fontSize;
    final fonts = settings.font.families;
    final base = TextStyle(
      color: rt.foreground,
      fontSize: size,
      height: settings.lineHeight,
      fontFamily: fonts.first,
      fontFamilyFallback: fonts.skip(1).toList(),
      letterSpacing: settings.letterSpacing == 0
          ? null
          : size * settings.letterSpacing,
      // Wider word gaps go with wider letter spacing, so words stay distinct.
      wordSpacing: settings.letterSpacing > 0
          ? size * settings.letterSpacing * 1.5
          : null,
    );

    if (block.type == BlockType.image) return _image(context, base);

    if (block.type == BlockType.separator) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: size),
        child: Center(
          child: Text(
            '*   *   *',
            style: base.copyWith(color: rt.foreground.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    final (style, align, padding) = switch (block.type) {
      BlockType.h1 => (
        base.copyWith(
          fontSize: size * 1.6,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        TextAlign.center,
        EdgeInsets.only(top: size * 1.5, bottom: size),
      ),
      BlockType.h2 => (
        base.copyWith(
          fontSize: size * 1.35,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        TextAlign.center,
        EdgeInsets.only(top: size * 1.2, bottom: size * 0.8),
      ),
      BlockType.h3 => (
        base.copyWith(
          fontSize: size * 1.15,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        TextAlign.center,
        EdgeInsets.only(top: size, bottom: size * 0.6),
      ),
      BlockType.quote => (
        base,
        TextAlign.start,
        EdgeInsets.only(left: size * 1.5, right: size, bottom: size * 0.6),
      ),
      BlockType.pre => (
        base.copyWith(
          fontFamily: 'Consolas',
          fontFamilyFallback: const ['Menlo', 'DejaVu Sans Mono', 'monospace'],
          fontSize: size * 0.85,
        ),
        TextAlign.start,
        EdgeInsets.only(bottom: size * 0.6),
      ),
      _ => (
        base,
        settings.justify ? TextAlign.justify : TextAlign.start,
        EdgeInsets.only(bottom: size * 0.35),
      ),
    };

    final indent = block.type == BlockType.paragraph;
    return Padding(
      padding: padding,
      child: _ReaderSelectableText(
        TextSpan(
          children: [
            // First-line indent, as in printed books.
            if (indent) WidgetSpan(child: SizedBox(width: size * 1.5)),
            ..._spans(rt == ReaderTheme.dark),
          ],
        ),
        style: style,
        textAlign: align,
        onSelectionChanged: (sel, cause) =>
            actions.selectionChanged(!sel.isCollapsed),
        contextMenuBuilder: _menu,
      ),
    );
  }

  /// Splits the text into spans wherever the style, a highlight or a search
  /// match starts or ends.
  List<InlineSpan> _spans(bool dark) {
    final text = block.text;
    final runStarts = <int>[];
    var pos = 0;
    for (final r in block.runs) {
      runStarts.add(pos);
      pos += r.text.length;
    }
    final cuts = <int>{0, text.length, ...runStarts};
    for (final h in highlights) {
      cuts
        ..add(h.start.clamp(0, text.length))
        ..add(h.end.clamp(0, text.length));
    }
    for (final (s, e) in searchMarks) {
      cuts
        ..add(s)
        ..add(e);
    }
    final sorted = cuts.toList()..sort();

    final spans = <InlineSpan>[];
    var run = 0;
    for (var i = 0; i + 1 < sorted.length; i++) {
      final a = sorted[i], b = sorted[i + 1];
      if (a >= b) continue;
      while (run + 1 < runStarts.length && runStarts[run + 1] <= a) {
        run++;
      }
      final r = block.runs[run];
      final h = highlights.where((h) => h.start <= a && a < h.end).lastOrNull;
      final mark = searchMarks.where((m) => m.$1 <= a && a < m.$2).firstOrNull;

      Color? bg;
      if (mark != null) {
        bg = mark == activeMark
            ? const Color(0xFFFF9800)
            : const Color(0xFFFF9800).withValues(alpha: 0.35);
      } else if (h != null) {
        bg = h.color.background(dark);
      }
      spans.add(
        TextSpan(
          text: text.substring(a, b),
          style: TextStyle(
            fontStyle: r.italic ? FontStyle.italic : null,
            fontWeight: r.bold ? FontWeight.w700 : null,
            backgroundColor: bg,
            // Highlights with a note get a dotted underline.
            decoration: h != null && h.hasNote
                ? TextDecoration.underline
                : null,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: h?.color.swatch,
            decorationThickness: 2,
          ),
        ),
      );
    }
    return spans;
  }

  Widget _menu(BuildContext context, EditableTextState state) {
    final value = state.textEditingValue;
    final text = block.text;
    // The indent is a placeholder character at the start of the text.
    final shift = value.text.startsWith('￼') ? 1 : 0;
    var start = (value.selection.start - shift).clamp(0, text.length);
    var end = (value.selection.end - shift).clamp(0, text.length);
    while (start < end && text[start].trim().isEmpty) {
      start++;
    }
    while (end > start && text[end - 1].trim().isEmpty) {
      end--;
    }
    // Snap to whole words, like Kindle: "si|ngle" becomes "single".
    bool letter(int i) =>
        RegExp(r"[\p{L}\p{N}'’-]", unicode: true).hasMatch(text[i]);
    if (start < end) {
      while (start > 0 && letter(start - 1) && letter(start)) {
        start--;
      }
      while (end < text.length && letter(end) && letter(end - 1)) {
        end++;
      }
    }
    final selected = text.substring(start, end);
    final hasText = selected.trim().isNotEmpty;
    final words = selected.trim().split(RegExp(r'\s+')).length;

    final touching = highlights
        .where(
          (h) => start == end
              ? h.start <= start && start <= h.end
              : h.start < end && start < h.end,
        )
        .firstOrNull;

    void run(VoidCallback f) {
      actions.menuChanged(false);
      state.hideToolbar();
      f();
    }

    actions.menuChanged(true);

    final items = <ContextMenuButtonItem>[
      if (hasText) ...[
        ContextMenuButtonItem(
          label: L10n.of(context).highlight,
          onPressed: () => run(() => actions.highlight(start, end, selected)),
        ),
        ContextMenuButtonItem(
          label: L10n.of(context).note,
          onPressed: () => run(() => actions.addNote(start, end, selected)),
        ),
        if (words <= 3)
          ContextMenuButtonItem(
            label: L10n.of(context).define,
            onPressed: () => run(() => actions.define(selected)),
          ),
        ContextMenuButtonItem(
          label: L10n.of(context).translate,
          onPressed: () => run(() => actions.translate(selected)),
        ),
      ],
      if (touching != null) ...[
        ContextMenuButtonItem(
          label: touching.hasNote
              ? L10n.of(context).editNote
              : L10n.of(context).editHighlight,
          onPressed: () => run(() => actions.editHighlight(touching)),
        ),
        ContextMenuButtonItem(
          label: L10n.of(context).removeHighlight,
          onPressed: () => run(() => actions.removeHighlight(touching)),
        ),
      ],
      ...state.contextMenuButtonItems.where(
        (i) =>
            i.type == ContextMenuButtonType.copy ||
            i.type == ContextMenuButtonType.selectAll,
      ),
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  Widget _image(BuildContext context, TextStyle base) {
    final bytes = imageBytes;
    if (bytes == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: settings.fontSize * 0.8),
      child: Column(
        children: [
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.zoomIn,
              child: GestureDetector(
                onTap: onImageTap,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxImageHeight),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          if (block.alt != null && block.alt!.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                block.alt!,
                textAlign: TextAlign.center,
                style: base.copyWith(
                  fontSize: settings.fontSize * 0.8,
                  fontStyle: FontStyle.italic,
                  color: base.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable paragraph text that leaves the reader's navigation keys
/// (arrows, page keys, space) to the reader instead of moving an invisible
/// caret and scrolling the page to it.
class _ReaderSelectableText extends StatefulWidget {
  final TextSpan span;
  final TextStyle style;
  final TextAlign textAlign;
  final SelectionChangedCallback onSelectionChanged;
  final EditableTextContextMenuBuilder contextMenuBuilder;

  const _ReaderSelectableText(
    this.span, {
    required this.style,
    required this.textAlign,
    required this.onSelectionChanged,
    required this.contextMenuBuilder,
  });

  @override
  State<_ReaderSelectableText> createState() => _ReaderSelectableTextState();
}

class _ReaderSelectableTextState extends State<_ReaderSelectableText> {
  static final _readerKeys = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.pageUp,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
  };

  late final FocusNode _focus = FocusNode(
    debugLabel: 'paragraph',
    onKeyEvent: (node, event) {
      // Shift+arrows still extend the selection.
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      return _readerKeys.contains(event.logicalKey)
          ? KeyEventResult.skipRemainingHandlers
          : KeyEventResult.ignored;
    },
  );

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectableText.rich(
    widget.span,
    focusNode: _focus,
    style: widget.style,
    textAlign: widget.textAlign,
    onSelectionChanged: widget.onSelectionChanged,
    contextMenuBuilder: widget.contextMenuBuilder,
  );
}

/// Full-screen, zoomable image.
void showImageViewer(BuildContext context, Uint8List bytes, String? caption) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: L10n.of(context).closeImage,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    pageBuilder: (ctx, _, __) => SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 6,
              child: Center(
                child: Image.memory(bytes, filterQuality: FilterQuality.high),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: L10n.of(context).close,
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          if (caption != null && caption.length > 3)
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
