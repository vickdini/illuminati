import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/annotation.dart';
import '../models/shelf.dart';

enum ReaderTheme { light, sepia, dark }

extension ReaderThemeColors on ReaderTheme {
  Color get background => switch (this) {
        ReaderTheme.light => const Color(0xFFFFFFFF),
        ReaderTheme.sepia => const Color(0xFFF4ECD8),
        ReaderTheme.dark => const Color(0xFF121212),
      };
  Color get foreground => switch (this) {
        ReaderTheme.light => const Color(0xFF1A1A1A),
        ReaderTheme.sepia => const Color(0xFF5B4636),
        ReaderTheme.dark => const Color(0xFFD6D6D6),
      };
  String get label => switch (this) {
        ReaderTheme.light => 'Light',
        ReaderTheme.sepia => 'Sepia',
        ReaderTheme.dark => 'Dark',
      };
}

/// Reader preferences and the catalog language, saved to `settings.json`.
class SettingsService extends ChangeNotifier {
  double fontSize = 19;
  double lineHeight = 1.6;
  bool serif = true;
  ReaderTheme readerTheme = ReaderTheme.light;

  /// Gutenberg language code for the catalog, or '' for all languages.
  String catalogLanguage = 'en';

  /// Learned reading speed (words per minute), for "minutes left".
  double readingWpm = 230;

  /// Language to translate selected text into.
  String translateTo =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  HighlightColor highlightColor = HighlightColor.yellow;

  /// Library screen: last view (see LibraryView) and sort order.
  String libraryView = 'all';
  LibrarySort librarySort = LibrarySort.recent;

  File? _file;

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _file = File(p.join(dir.path, 'settings.json'));
    if (await _file!.exists()) {
      try {
        final j = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
        fontSize = (j['fontSize'] as num?)?.toDouble() ?? fontSize;
        lineHeight = (j['lineHeight'] as num?)?.toDouble() ?? lineHeight;
        serif = j['serif'] as bool? ?? serif;
        readerTheme = ReaderTheme.values.firstWhere(
            (t) => t.name == j['readerTheme'],
            orElse: () => readerTheme);
        catalogLanguage = j['catalogLanguage'] as String? ?? catalogLanguage;
        readingWpm = (j['readingWpm'] as num?)?.toDouble() ?? readingWpm;
        translateTo = j['translateTo'] as String? ?? translateTo;
        highlightColor = HighlightColor.values.firstWhere(
            (c) => c.name == j['highlightColor'],
            orElse: () => highlightColor);
        libraryView = j['libraryView'] as String? ?? libraryView;
        librarySort = LibrarySort.values.firstWhere((x) => x.name == j['librarySort'],
            orElse: () => librarySort);
      } catch (_) {}
    }
  }

  void update(void Function(SettingsService s) change) {
    change(this);
    notifyListeners();
    _file?.writeAsString(jsonEncode({
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'serif': serif,
      'readerTheme': readerTheme.name,
      'catalogLanguage': catalogLanguage,
      'readingWpm': readingWpm,
      'translateTo': translateTo,
      'highlightColor': highlightColor.name,
      'libraryView': libraryView,
      'librarySort': librarySort.name,
    }));
  }
}
