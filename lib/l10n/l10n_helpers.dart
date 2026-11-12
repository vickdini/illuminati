import 'dart:async';

import '../models/book.dart';
import '../models/shelf.dart';
import '../services/app_error.dart';
import '../services/settings_service.dart';
import '../sources/internet_archive.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Interface languages, by code, named in their own language.
const appLanguages = <(String, String)>[
  ('en', 'English'),
  ('es', 'Español'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
  ('it', 'Italiano'),
  ('pt', 'Português'),
];

/// A sentence for any error, in the reader's language.
String errorText(L10n t, Object error) {
  if (error is AppException) {
    final status = error.status ?? 0;
    final host = error.host ?? '';
    return switch (error.code) {
      ErrorCode.catalogHttp => t.errCatalogHttp(status),
      ErrorCode.searchFailed => t.errSearchFailed,
      ErrorCode.noOtherEdition => t.errNoOtherEdition,
      ErrorCode.noEpub => t.errNoEpub,
      ErrorCode.downloadTimeout => t.errDownloadTimeout,
      ErrorCode.downloadHttp => t.errDownloadHttp(status),
      ErrorCode.invalidEpub => t.errInvalidEpub,
      ErrorCode.wikisourceTooLong => t.errWikisourceTooLong,
      ErrorCode.dictionaryUnavailable => t.errDictionary(status),
      ErrorCode.translationUnavailable => t.errTranslationUnavailable(status),
      ErrorCode.translationQuota => t.errTranslationQuota,
      // The translation service's own message (in English) when it gave one.
      ErrorCode.translationFailed =>
        error.detail ?? t.errTranslationFailed(status),
      ErrorCode.sourceBusy => t.errSourceBusy(host),
      ErrorCode.sourceHttp => t.errSourceHttp(host, status),
    };
  }
  if (error is TimeoutException) return t.errTimeout;
  return t.errGeneric;
}

String themeLabel(L10n t, ReaderTheme theme) => switch (theme) {
  ReaderTheme.light => t.themeLight,
  ReaderTheme.sepia => t.themeSepia,
  ReaderTheme.dark => t.themeDark,
};

String fontDescription(L10n t, ReaderFont font) => switch (font) {
  ReaderFont.serif => t.fontDescSerif,
  ReaderFont.garamond => t.fontDescGaramond,
  ReaderFont.sans => t.fontDescSans,
  ReaderFont.dyslexic => t.fontDescDyslexic,
};

String sortLabel(L10n t, LibrarySort sort) => switch (sort) {
  LibrarySort.recent => t.sortRecent,
  LibrarySort.title => t.sortTitle,
  LibrarySort.author => t.sortAuthor,
  LibrarySort.progress => t.sortProgress,
  LibrarySort.added => t.sortAdded,
};

/// One line under each catalog's row title.
String sourceTagline(L10n t, String sourceId) => switch (sourceId) {
  'standardebooks' => t.taglineStandardEbooks,
  'wikisource' => t.taglineWikisource,
  'archive' => t.taglineArchive,
  _ => '',
};

/// The copyright note shown on a book's page.
String rightsNote(L10n t, Book book) => switch (book.source) {
  'gutenberg' => t.rightsGutenberg(book.id),
  'standardebooks' => t.rightsStandardEbooks,
  'wikisource' => t.rightsWikisource,
  'archive' => t.rightsArchive(
    '${InternetArchiveSource.latestPublicDomainYear}',
  ),
  _ => '',
};

/// The book's authors, or "Unknown author" in the reader's language.
String authorLine(L10n t, Book book) =>
    book.authors.isEmpty ? t.unknownAuthor : book.authorLine;

/// Names of the languages text can be translated into.
String languageName(L10n t, String code) => switch (code) {
  'ar' => t.langAr,
  'zh' => t.langZh,
  'nl' => t.langNl,
  'en' => t.langEn,
  'fr' => t.langFr,
  'de' => t.langDe,
  'el' => t.langEl,
  'he' => t.langHe,
  'hi' => t.langHi,
  'it' => t.langIt,
  'ja' => t.langJa,
  'ko' => t.langKo,
  'pl' => t.langPl,
  'pt' => t.langPt,
  'ru' => t.langRu,
  'es' => t.langEs,
  'sv' => t.langSv,
  'tr' => t.langTr,
  _ => code,
};
