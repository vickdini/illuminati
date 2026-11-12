import 'dart:async';
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

/// The reading typeface. All four are bundled with the app (SIL Open Font
/// License), so books look the same on every device. The enum names are
/// stored in settings: [serif] is Literata and [sans] is Atkinson Hyperlegible.
enum ReaderFont { serif, garamond, sans, dyslexic }

/// System fonts used only for characters a bundled font lacks (e.g. Chinese,
/// or Greek in Atkinson Hyperlegible).
const _serifFallback = ['Noto Serif', 'Georgia', 'Times New Roman', 'DejaVu Serif', 'serif'];
const _sansFallback = ['Noto Sans', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'DejaVu Sans', 'sans-serif'];

extension ReaderFontInfo on ReaderFont {
  String get label => switch (this) {
        ReaderFont.serif => 'Literata',
        ReaderFont.garamond => 'EB Garamond',
        ReaderFont.sans => 'Atkinson',
        ReaderFont.dyslexic => 'OpenDyslexic',
      };

  String get description => switch (this) {
        ReaderFont.serif => 'Literata: a serif designed for reading on screens.',
        ReaderFont.garamond => 'EB Garamond: a classic book face, based on 16th-century type.',
        ReaderFont.sans => 'Atkinson Hyperlegible: a sans-serif designed by the Braille '
            'Institute so that similar letters are easy to tell apart.',
        ReaderFont.dyslexic => 'OpenDyslexic has weighted letter bottoms to help keep letters '
            'from flipping or swapping. Many readers also find extra letter spacing and '
            'unjustified text easier.',
      };

  /// The bundled family, then system fallbacks for missing characters.
  List<String> get families => switch (this) {
        ReaderFont.serif => const ['Literata', ..._serifFallback],
        ReaderFont.garamond => const ['EB Garamond', 'Literata', ..._serifFallback],
        ReaderFont.sans => const ['Atkinson Hyperlegible', ..._sansFallback],
        ReaderFont.dyslexic => const ['OpenDyslexic', ..._sansFallback],
      };
}

/// Literata with fallbacks, for reading-style text outside the book view.
const readingSerif = ['Literata', ..._serifFallback];

/// Reader preferences, display and accessibility settings, and a few
/// remembered choices, saved to `settings.json`.
class SettingsService extends ChangeNotifier {
  // ---------- Reading text ----------
  double fontSize = 19;
  double lineHeight = 1.6;
  ReaderFont font = ReaderFont.serif;
  ReaderTheme readerTheme = ReaderTheme.light;

  /// Space added between letters, as a fraction of the font size
  /// (-0.08..0.15). Negative tightens wide fonts such as OpenDyslexic.
  double letterSpacing = 0;

  /// Justified text (even right edge). Ragged-right is easier for many
  /// dyslexic readers, as it avoids uneven gaps between words.
  bool justify = true;

  // ---------- Page layout ----------
  /// Minimum space on each side of the text, in logical pixels.
  double margin = 24;

  /// Maximum width of the text column, in logical pixels.
  double lineWidth = 680;

  // ---------- Screen (whole app) ----------
  /// 1 = normal; lower dims everything drawn by the app (0.3..1).
  double brightness = 1;

  /// 0 = neutral; higher removes blue light for a warmer, amber look (0..1).
  double warmth = 0;

  // ---------- Remembered choices ----------
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
        fromJson(jsonDecode(await _file!.readAsString()) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  void fromJson(Map<String, dynamic> j) {
    double num_(String k, double fallback) => (j[k] as num?)?.toDouble() ?? fallback;
    T enum_<T extends Enum>(List<T> values, String k, T fallback) =>
        values.firstWhere((v) => v.name == j[k], orElse: () => fallback);

    fontSize = num_('fontSize', fontSize);
    lineHeight = num_('lineHeight', lineHeight);
    // Before OpenDyslexic, the font was a serif/sans switch.
    font = j.containsKey('font')
        ? enum_(ReaderFont.values, 'font', font)
        : (j['serif'] == false ? ReaderFont.sans : ReaderFont.serif);
    readerTheme = enum_(ReaderTheme.values, 'readerTheme', readerTheme);
    letterSpacing = num_('letterSpacing', letterSpacing).clamp(-0.08, 0.15);
    justify = j['justify'] as bool? ?? justify;
    margin = num_('margin', margin).clamp(8.0, 120.0);
    lineWidth = num_('lineWidth', lineWidth).clamp(360.0, 1200.0);
    brightness = num_('brightness', brightness).clamp(0.3, 1.0);
    warmth = num_('warmth', warmth).clamp(0.0, 1.0);
    catalogLanguage = j['catalogLanguage'] as String? ?? catalogLanguage;
    readingWpm = num_('readingWpm', readingWpm);
    translateTo = j['translateTo'] as String? ?? translateTo;
    highlightColor = enum_(HighlightColor.values, 'highlightColor', highlightColor);
    libraryView = j['libraryView'] as String? ?? libraryView;
    librarySort = enum_(LibrarySort.values, 'librarySort', librarySort);
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'font': font.name,
        'readerTheme': readerTheme.name,
        'letterSpacing': letterSpacing,
        'justify': justify,
        'margin': margin,
        'lineWidth': lineWidth,
        'brightness': brightness,
        'warmth': warmth,
        'catalogLanguage': catalogLanguage,
        'readingWpm': readingWpm,
        'translateTo': translateTo,
        'highlightColor': highlightColor.name,
        'libraryView': libraryView,
        'librarySort': librarySort.name,
      };

  /// Puts the text and screen settings back to their defaults.
  void resetDisplay() => update((s) {
        final d = SettingsService._defaults();
        s
          ..fontSize = d.fontSize
          ..lineHeight = d.lineHeight
          ..font = d.font
          ..letterSpacing = d.letterSpacing
          ..justify = d.justify
          ..margin = d.margin
          ..lineWidth = d.lineWidth
          ..brightness = d.brightness
          ..warmth = d.warmth;
      });

  SettingsService();
  SettingsService._defaults();

  Timer? _saveTimer;
  Future<void> _saving = Future.value();

  void update(void Function(SettingsService s) change) {
    change(this);
    notifyListeners();
    // Sliders send many changes per second: save once they settle, one
    // write at a time.
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      final file = _file;
      if (file == null) return;
      final json = jsonEncode(toJson());
      _saving = _saving.then((_) async {
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString(json);
        await tmp.rename(file.path);
      }).catchError((Object e) {
        debugPrint('Could not save settings: $e');
      });
    });
  }

  // ---------- Screen filter ----------

  /// Whether [screenFilter] changes anything.
  bool get hasScreenFilter => brightness < 0.999 || warmth > 0.001;

  /// A color matrix that dims (brightness) and warms (cuts blue, a little
  /// green) everything the app draws, like a night-light.
  List<double> get screenFilter {
    final b = brightness;
    final g = b * (1 - 0.18 * warmth);
    final bl = b * (1 - 0.62 * warmth);
    return [
      b, 0, 0, 0, 0, //
      0, g, 0, 0, 0,
      0, 0, bl, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
