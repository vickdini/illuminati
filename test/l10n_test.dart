import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:illuminati/l10n/l10n_helpers.dart';
import 'package:illuminati/models/book.dart';
import 'package:illuminati/screens/lookup_sheet.dart' show sortedTranslateLanguages;
import 'package:illuminati/services/app_error.dart';

void main() {
  test('every language has every string, with the same placeholders', () {
    Map<String, dynamic> arb(String lang) =>
        jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
    final en = arb('en');
    final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
    Set<String> placeholders(String s) =>
        RegExp(r'\{(\w+)[,}]').allMatches(s).map((m) => m[1]!).toSet();
    for (final (code, _) in appLanguages.where((l) => l.$1 != 'en')) {
      final t = arb(code);
      expect(t.keys.where((k) => !k.startsWith('@')).toSet(), keys, reason: code);
      for (final k in keys) {
        expect(placeholders(t[k] as String), placeholders(en[k] as String), reason: '$code: $k');
      }
    }
    expect(L10n.supportedLocales.map((l) => l.languageCode).toSet(),
        appLanguages.map((l) => l.$1).toSet());
  });

  test('plurals, errors and sorted language names', () {
    final es = lookupL10n(const Locale('es'));
    expect(es.bookCount(1), '1 libro');
    expect(es.bookCount(3), '3 libros');
    expect(es.minutesLeft(1), 'Queda 1 min del capítulo');
    expect(lookupL10n(const Locale('de')).bookCount(2), '2 Bücher');
    expect(errorText(es, const AppException(ErrorCode.downloadHttp, status: 404)),
        'La descarga falló (404).');
    expect(errorText(es, const AppException(ErrorCode.translationFailed, detail: 'Quota')),
        'Quota', reason: "the service's own message passes through");
    expect(authorLine(es, const Book(id: 1, title: 'X', authors: [])), 'Autor desconocido');
    expect(rightsNote(es, const Book(id: 1, title: 'X', authors: [], source: 'archive')),
        contains('${DateTime.now().year - 96}'), reason: 'the year is not formatted as 1.930');

    final names = sortedTranslateLanguages(es).map((l) => l.$2).toList();
    expect(names.take(3), ['Alemán', 'Árabe', 'Chino'], reason: 'accents ignored when sorting');
  });
}
