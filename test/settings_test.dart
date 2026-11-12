import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:illuminati/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('old serif switch migrates to the font choice', () {
    expect((SettingsService()..fromJson({'serif': false})).font, ReaderFont.sans);
    expect((SettingsService()..fromJson({'serif': true})).font, ReaderFont.serif);
    expect((SettingsService()..fromJson({'font': 'dyslexic', 'serif': true})).font,
        ReaderFont.dyslexic, reason: 'the new key wins');
  });

  test('values round-trip and are kept in range', () {
    final s = SettingsService()
      ..fromJson({
        'letterSpacing': 0.5,
        'margin': 1,
        'lineWidth': 5000,
        'brightness': 0.1,
        'warmth': 0.4,
        'justify': false,
      });
    expect(s.letterSpacing, 0.15);
    expect((SettingsService()..fromJson({'letterSpacing': -1})).letterSpacing, -0.08);
    expect(s.margin, 8);
    expect(s.lineWidth, 1200);
    expect(s.brightness, 0.3, reason: 'never so dark the app becomes unusable');
    final copy = SettingsService()..fromJson(s.toJson());
    expect((copy.warmth, copy.justify, copy.lineWidth), (0.4, false, 1200.0));
  });

  test('screen filter: identity by default, dims and warms otherwise', () {
    final s = SettingsService();
    expect(s.hasScreenFilter, isFalse);
    s.brightness = 0.5;
    s.warmth = 1;
    expect(s.hasScreenFilter, isTrue);
    final m = s.screenFilter;
    final (r, g, b) = (m[0], m[6], m[12]);
    expect(r, 0.5);
    expect(g, lessThan(r));
    expect(b, lessThan(g), reason: 'warmth removes the most blue');
    expect(m[18], 1, reason: 'alpha untouched');
  });

  test('reset restores display settings only', () async {
    final s = SettingsService()
      ..font = ReaderFont.dyslexic
      ..warmth = 0.8
      ..catalogLanguage = 'es';
    s.resetDisplay();
    expect((s.font, s.warmth, s.catalogLanguage), (ReaderFont.serif, 0.0, 'es'));
    await Future<void>.delayed(const Duration(milliseconds: 500)); // let the save timer run
  });

  test('every reading font is bundled, with all files and its licence', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final f in ReaderFont.values) {
      final family = f.families.first;
      expect(pubspec, contains('- family: $family'), reason: '$family must be declared');
    }
    final assets = RegExp(r'- asset: (assets/fonts/\S+)').allMatches(pubspec).map((m) => m[1]!);
    expect(assets.length, 16, reason: '4 families x regular, bold, italic, bold italic');
    for (final a in assets) {
      expect(File(a).existsSync(), isTrue, reason: '$a is missing');
      expect(File('${File(a).parent.path}/OFL.txt').existsSync(), isTrue);
    }
    expect(readingSerif.first, 'Literata');
  });
}
