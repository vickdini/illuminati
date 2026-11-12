import 'package:flutter/material.dart';

import '../main.dart';
import '../services/lookup_service.dart';

const translateLanguages = <(String, String)>[
  ('en', 'English'),
  ('es', 'Spanish'),
  ('fr', 'French'),
  ('de', 'German'),
  ('it', 'Italian'),
  ('pt', 'Portuguese'),
  ('nl', 'Dutch'),
  ('ru', 'Russian'),
  ('pl', 'Polish'),
  ('sv', 'Swedish'),
  ('el', 'Greek'),
  ('tr', 'Turkish'),
  ('ar', 'Arabic'),
  ('he', 'Hebrew'),
  ('hi', 'Hindi'),
  ('zh', 'Chinese'),
  ('ja', 'Japanese'),
  ('ko', 'Korean'),
];

enum LookupMode { define, translate }

/// Bottom sheet with a dictionary definition or a translation of [text].
void showLookup(
  BuildContext context,
  String text, {
  required LookupMode mode,
  String? bookLanguage,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (ctx, scroll) => _LookupSheet(
        text: text,
        mode: mode,
        bookLanguage: bookLanguage,
        scroll: scroll,
      ),
    ),
  );
}

class _LookupSheet extends StatefulWidget {
  final String text;
  final LookupMode mode;
  final String? bookLanguage;
  final ScrollController scroll;
  const _LookupSheet({
    required this.text,
    required this.mode,
    required this.bookLanguage,
    required this.scroll,
  });

  @override
  State<_LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends State<_LookupSheet> {
  late LookupMode _mode = widget.mode;
  late final bool _canDefine =
      widget.text.trim().split(RegExp(r'\s+')).length <= 3;
  Future<List<DictionaryEntry>>? _definitions;
  Future<Translation>? _translation;
  String? _translatedTo;

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final theme = Theme.of(context);
    final target = services.settings.translateTo;

    if (_mode == LookupMode.define && _definitions == null) {
      _definitions = services.lookup.define(
        widget.text,
        preferLanguage: widget.bookLanguage,
      );
    }
    final sameLanguage = widget.bookLanguage == target;
    if (_mode == LookupMode.translate &&
        !sameLanguage &&
        (_translation == null || _translatedTo != target)) {
      _translatedTo = target;
      _translation = services.lookup.translate(
        widget.text,
        from: widget.bookLanguage,
        to: target,
      );
    }

    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _mode == LookupMode.define
                    ? LookupService.cleanWord(widget.text)
                    : 'Translation',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Georgia',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SegmentedButton<LookupMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: LookupMode.define,
                  label: const Text('Define'),
                  icon: const Icon(Icons.menu_book_outlined),
                  enabled: _canDefine,
                ),
                const ButtonSegment(
                  value: LookupMode.translate,
                  label: Text('Translate'),
                  icon: Icon(Icons.translate),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_mode == LookupMode.define)
          _defineView(theme)
        else
          _translateView(theme, target),
      ],
    );
  }

  Widget _defineView(ThemeData theme) {
    return FutureBuilder<List<DictionaryEntry>>(
      future: _definitions,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _message(theme, Icons.cloud_off, '${snap.error}');
        }
        final entries = snap.data ?? const [];
        if (entries.isEmpty) {
          return Column(
            children: [
              _message(theme, Icons.search_off, 'No definition found.'),
              TextButton.icon(
                icon: const Icon(Icons.translate),
                label: const Text('Translate instead'),
                onPressed: () => setState(() => _mode = LookupMode.translate),
              ),
            ],
          );
        }
        String? lastLanguage;
        final children = <Widget>[];
        for (final e in entries.take(8)) {
          if (e.language != lastLanguage) {
            lastLanguage = e.language;
            children.add(
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  e.language,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            );
          }
          children.add(
            Text(
              e.partOfSpeech,
              style: theme.textTheme.titleSmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          );
          for (var i = 0; i < e.definitions.length && i < 6; i++) {
            children.add(
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '${i + 1}. ${e.definitions[i]}',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            );
          }
          children.add(const SizedBox(height: 12));
        }
        children.add(
          Text(
            'Definitions from Wiktionary (CC BY-SA).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  Widget _translateView(ThemeData theme, String target) {
    final settings = Services.of(context).settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: 8,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Into: '),
            DropdownButton<String>(
              value: translateLanguages.any((l) => l.$1 == target)
                  ? target
                  : 'en',
              items: [
                for (final l in translateLanguages)
                  DropdownMenuItem(value: l.$1, child: Text(l.$2)),
              ],
              onChanged: (v) {
                if (v == null) return;
                settings.update((s) => s.translateTo = v);
                setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.bookLanguage == target)
          _message(
            theme,
            Icons.translate,
            'This book is already in that language. Choose another one above.',
          )
        else
          FutureBuilder<Translation>(
            future: _translation,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return _message(theme, Icons.cloud_off, '${snap.error}');
              }
              return SelectableText(
                snap.data!.text,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
              );
            },
          ),
        const SizedBox(height: 16),
        Text(
          'Translations by MyMemory. Selected text is sent to their service.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _message(ThemeData theme, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(icon, size: 36, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}
