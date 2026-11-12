// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class L10nDe extends L10n {
  L10nDe([String locale = 'de']) : super(locale);

  @override
  String get cancel => 'Abbrechen';

  @override
  String get remove => 'Entfernen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get done => 'Fertig';

  @override
  String get create => 'Erstellen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get back => 'Zurück';

  @override
  String get undo => 'Rückgängig';

  @override
  String get close => 'Schließen';

  @override
  String get unknownAuthor => 'Unbekannter Autor';

  @override
  String get about => 'Über';

  @override
  String get displayAccessibility => 'Anzeige & Barrierefreiheit';

  @override
  String get aboutText =>
      'Mit Illuminati findest, lädst und liest du Bücher, die nie urheberrechtlich geschützt waren oder deren Schutz abgelaufen ist.\n\nDie Bücher stammen von Project Gutenberg (gutenberg.org), Standard Ebooks (standardebooks.org), Wikisource (wikisource.org, als EPUBs von WS Export) und dem Internet Archive (archive.org). In den USA sind sie gemeinfrei, mit Ausnahme einiger Wikisource-Texte unter freien Lizenzen. Das Urheberrecht unterscheidet sich von Land zu Land; prüfe daher vor dem Herunterladen die Gesetze deines Landes.\n\nWortdefinitionen stammen aus dem Wiktionary, Übersetzungen von MyMemory; der markierte Text wird an diese Dienste gesendet.';

  @override
  String get discoverFreeBooks => 'Kostenlose Bücher entdecken';

  @override
  String get discoverSubtitle =>
      'Klassiker, deren Urheberrecht abgelaufen ist – kostenlos zum Herunterladen und Behalten.';

  @override
  String get searchHint => 'Nach Titel oder Autor suchen';

  @override
  String get catalogLanguage => 'Katalogsprache';

  @override
  String get allLanguages => 'Alle Sprachen';

  @override
  String get gutenbergSubtitle =>
      'Die größte kostenlose Bibliothek: über 75.000 gemeinfreie Bücher';

  @override
  String get noBooksFound =>
      'Keine Bücher gefunden. Versuche eine andere Suche.';

  @override
  String get catalogTimeout => 'Der Katalog antwortet zu langsam.';

  @override
  String get catalogOffline =>
      'Der Katalog konnte nicht geladen werden. Prüfe deine Internetverbindung.';

  @override
  String couldNotReach(String source) {
    return '$source ist nicht erreichbar.';
  }

  @override
  String get downloadFree => 'Kostenlos herunterladen';

  @override
  String get yourLibrary => 'Deine Bibliothek';

  @override
  String libraryAndShelves(int count) {
    return 'Bibliothek & Regale ($count)';
  }

  @override
  String get libraryEmptyHome =>
      'Deine Bibliothek ist leer. Bücher, die du aus dem Katalog herunterlädst, erscheinen hier und lassen sich offline lesen.';

  @override
  String noDownloadedSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Keine heruntergeladenen Bücher. Deine $count gespeicherten Bücher findest du unter Bibliothek & Regale.',
      one:
          'Keine heruntergeladenen Bücher. Dein gespeichertes Buch findest du unter Bibliothek & Regale.',
    );
    return '$_temp0';
  }

  @override
  String get catPopular => 'Beliebt';

  @override
  String get catFiction => 'Belletristik';

  @override
  String get catMystery => 'Krimi';

  @override
  String get catAdventure => 'Abenteuer';

  @override
  String get catScienceFiction => 'Science-Fiction';

  @override
  String get catRomance => 'Liebesromane';

  @override
  String get catHorror => 'Horror';

  @override
  String get catFantasy => 'Fantasy';

  @override
  String get catChildren => 'Kinderbücher';

  @override
  String get catPoetry => 'Lyrik';

  @override
  String get catDrama => 'Drama';

  @override
  String get catPhilosophy => 'Philosophie';

  @override
  String get catHistory => 'Geschichte';

  @override
  String get catScience => 'Wissenschaft';

  @override
  String get catBiography => 'Biografien';

  @override
  String get taglineStandardEbooks =>
      'Sorgfältig gesetzte und korrekturgelesene Klassiker';

  @override
  String get taglineWikisource =>
      'Von Freiwilligen abgeschriebene Texte in vielen Sprachen';

  @override
  String get taglineArchive =>
      'Scans alter gedruckter Ausgaben (Text per OCR erstellt)';

  @override
  String rightsGutenberg(int id) {
    return 'Von Project Gutenberg (E-Book Nr. $id). Dieses Buch ist in den USA gemeinfrei. Das Urheberrecht unterscheidet sich von Land zu Land; prüfe daher vor dem Herunterladen die Gesetze deines Landes.';
  }

  @override
  String get rightsStandardEbooks =>
      'Von Standard Ebooks. Deren Ausgaben sind in den USA gemeinfrei, und die eigenen Änderungen sind per CC0 gemeinfrei gestellt. Das Urheberrecht unterscheidet sich von Land zu Land; prüfe daher die Gesetze deines Landes.';

  @override
  String get rightsWikisource =>
      'Von Wikisource, von Freiwilligen abgeschrieben; das EPUB erzeugt WS Export. Wikisource enthält gemeinfreie Texte und einige unter freien Lizenzen (etwa CC BY-SA), die freies Lesen und Weitergeben erlauben. Prüfe die Gesetze deines Landes.';

  @override
  String rightsArchive(String year) {
    return 'Aus dem Internet Archive. Angezeigt werden nur Bücher, die $year oder früher erschienen sind; sie sind daher in den USA gemeinfrei. Der Text des EPUB wurde automatisch aus Scans erzeugt und kann Fehler enthalten. Das Urheberrecht unterscheidet sich von Land zu Land; prüfe daher die Gesetze deines Landes.';
  }

  @override
  String addedToLibrary(String title) {
    return '„$title“ wurde deiner Bibliothek hinzugefügt';
  }

  @override
  String couldNotDownload(String title, String error) {
    return '„$title“ konnte nicht heruntergeladen werden: $error';
  }

  @override
  String get removeFromLibraryQuestion => 'Aus der Bibliothek entfernen?';

  @override
  String removeFromLibraryBody(String title) {
    return '„$title“ wird mitsamt Notizen, Markierungen und Lesezeichen aus deiner Bibliothek und deinen Regalen entfernt. Du kannst es jederzeit erneut herunterladen.';
  }

  @override
  String get continueReading => 'Weiterlesen';

  @override
  String get readNow => 'Jetzt lesen';

  @override
  String get downloading => 'Wird heruntergeladen …';

  @override
  String downloadingPercent(int percent) {
    return 'Wird heruntergeladen: $percent %';
  }

  @override
  String get noEbookEdition => 'Keine E-Book-Ausgabe';

  @override
  String get freeToRead => 'Frei lesbar';

  @override
  String get publicDomain => 'Gemeinfrei';

  @override
  String downloadsCount(String count) {
    return '$count Downloads';
  }

  @override
  String get getIllustratedEdition => 'Illustrierte Ausgabe laden';

  @override
  String get illustratedDownloaded => 'Illustrierte Ausgabe heruntergeladen';

  @override
  String get removeDownload => 'Download entfernen';

  @override
  String get removeFromLibrary => 'Aus der Bibliothek entfernen';

  @override
  String get aboutThisBook => 'Über dieses Buch';

  @override
  String get subjects => 'Themen';

  @override
  String get wantToRead => 'Möchte ich lesen';

  @override
  String get finished => 'Gelesen';

  @override
  String get addToShelf => 'Zu einem Regal hinzufügen';

  @override
  String onShelf(String name) {
    return 'Im Regal „$name“';
  }

  @override
  String onShelves(int count) {
    return 'In $count Regalen';
  }

  @override
  String get newShelf => 'Neues Regal';

  @override
  String get newShelfEllipsis => 'Neues Regal …';

  @override
  String get shelfNameHint => 'z. B. Favoriten, Philosophie, Zu lesen';

  @override
  String get renameShelf => 'Regal umbenennen';

  @override
  String get deleteShelf => 'Regal löschen';

  @override
  String deleteShelfQuestion(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get deleteShelfBody =>
      'Das Regal wird gelöscht; seine Bücher bleiben in deiner Bibliothek.';

  @override
  String get noShelvesYet =>
      'Du hast noch keine Regale. Erstelle eines, um Bücher nach Belieben zu gruppieren.';

  @override
  String bookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get bookDetails => 'Buchdetails';

  @override
  String get addToShelfEllipsis => 'Zu einem Regal hinzufügen …';

  @override
  String get removeFromWantToRead => 'Aus „Möchte ich lesen“ entfernen';

  @override
  String get markNotFinished => 'Als ungelesen markieren';

  @override
  String get markFinished => 'Als gelesen markieren';

  @override
  String downloadRemoved(String title) {
    return 'Download entfernt. „$title“ bleibt mit deinen Notizen und deiner Leseposition in deiner Bibliothek.';
  }

  @override
  String get sort => 'Sortieren';

  @override
  String get filterHint => 'Nach Titel oder Autor filtern';

  @override
  String get viewAll => 'Alle';

  @override
  String get viewDownloaded => 'Heruntergeladen';

  @override
  String get viewReading => 'Am Lesen';

  @override
  String get shelfHint =>
      'Klicke mit der rechten Maustaste auf ein Regal oder halte es gedrückt, um es umzubenennen oder zu löschen. Bücher fügst du bei jedem Buch mit „Zu einem Regal hinzufügen“ hinzu.';

  @override
  String noBooksMatch(String query) {
    return 'Keine Bücher passen zu „$query“.';
  }

  @override
  String get emptyShelf =>
      'Dieses Regal ist leer.\nÖffne ein Buch und wähle „Zu einem Regal hinzufügen“.';

  @override
  String get emptyDownloaded => 'Keine heruntergeladenen Bücher.';

  @override
  String get emptyWantToRead =>
      'Noch nichts hier.\nMarkiere Bücher im Katalog mit „Möchte ich lesen“; sie werden gespeichert, ohne sie herunterzuladen.';

  @override
  String get emptyReading => 'Du liest gerade kein Buch.';

  @override
  String get emptyFinished =>
      'Hier erscheinen Bücher, die du zu Ende gelesen hast.';

  @override
  String get emptyLibrary => 'Deine Bibliothek ist leer.';

  @override
  String get sortRecent => 'Zuletzt gelesen';

  @override
  String get sortTitle => 'Titel';

  @override
  String get sortAuthor => 'Autor';

  @override
  String get sortProgress => 'Fortschritt';

  @override
  String get sortAdded => 'Zuletzt hinzugefügt';

  @override
  String get tileNew => 'Neu';

  @override
  String get notDownloaded => 'Nicht heruntergeladen';

  @override
  String get note => 'Notiz';

  @override
  String get writeNote => 'Notiz schreiben …';

  @override
  String get removeHighlight => 'Markierung entfernen';

  @override
  String get contents => 'Inhalt';

  @override
  String bookmarksCount(int count) {
    return 'Lesezeichen ($count)';
  }

  @override
  String notesCount(int count) {
    return 'Notizen ($count)';
  }

  @override
  String get unknownChapter => 'Unbekanntes Kapitel';

  @override
  String get noBookmarks =>
      'Noch keine Lesezeichen.\nNutze die Lesezeichen-Schaltfläche in der Symbolleiste (oder Strg+B).';

  @override
  String get bookmark => 'Lesezeichen';

  @override
  String get deleteBookmark => 'Lesezeichen löschen';

  @override
  String get noHighlights =>
      'Noch keine Markierungen.\nMarkiere Text und wähle Markieren oder Notiz. Am Computer klickst du mit der rechten Maustaste auf die Auswahl.';

  @override
  String get copyAllMarkdown => 'Alles als Markdown kopieren';

  @override
  String get notesCopied => 'Notizen in die Zwischenablage kopiert';

  @override
  String get editNote => 'Notiz bearbeiten';

  @override
  String get addNote => 'Notiz hinzufügen';

  @override
  String get editHighlight => 'Markierung bearbeiten';

  @override
  String get highlight => 'Markieren';

  @override
  String get define => 'Nachschlagen';

  @override
  String get translate => 'Übersetzen';

  @override
  String get closeImage => 'Bild schließen';

  @override
  String bookOpenError(String error) {
    return 'Dieses Buch konnte nicht geöffnet werden.\n$error';
  }

  @override
  String get lessThanMinuteLeft =>
      'Weniger als eine Minute bis zum Kapitelende';

  @override
  String minutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Noch $minutes Min. im Kapitel',
      one: 'Noch 1 Min. im Kapitel',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutesLeft(int hours, int minutes) {
    return 'Noch $hours Std. $minutes Min. im Kapitel';
  }

  @override
  String finishedBook(String title) {
    return 'Du hast „$title“ zu Ende gelesen. Es steht jetzt in deiner Liste „Gelesen“.';
  }

  @override
  String get search => 'Suchen';

  @override
  String searchNoMatches(String query) {
    return '„$query“ · keine Treffer';
  }

  @override
  String searchPosition(String query, int index, int total) {
    return '„$query“ · $index von $total';
  }

  @override
  String get previousMatch => 'Vorheriger Treffer';

  @override
  String get nextMatch => 'Nächster Treffer (F3)';

  @override
  String get closeSearch => 'Suche schließen';

  @override
  String get theEnd => '— Ende —';

  @override
  String nextChapterTitle(String title) {
    return 'Weiter: $title';
  }

  @override
  String get backToLibrary => 'Zurück zur Bibliothek';

  @override
  String get searchInBookShortcut => 'Im Buch suchen (Strg+F)';

  @override
  String get removeBookmarkShortcut => 'Lesezeichen entfernen (Strg+B)';

  @override
  String get bookmarkPageShortcut => 'Lesezeichen für diese Seite (Strg+B)';

  @override
  String get contentsBookmarksNotes => 'Inhalt, Lesezeichen & Notizen';

  @override
  String get displaySettings => 'Anzeigeeinstellungen';

  @override
  String get previousChapter => 'Vorheriges Kapitel';

  @override
  String get nextChapter => 'Nächstes Kapitel';

  @override
  String chapterStatus(String title, int index, int total, int percent) {
    return '$title  ·  Kapitel $index von $total  ·  $percent % gelesen';
  }

  @override
  String get searchInThisBook => 'In diesem Buch suchen';

  @override
  String get typeTwoLetters => 'Gib mindestens zwei Buchstaben ein.';

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer',
      one: '1 Treffer',
      zero: 'Keine Treffer',
    );
    return '$_temp0';
  }

  @override
  String matchesMany(int count) {
    return 'Über $count Treffer';
  }

  @override
  String get translation => 'Übersetzung';

  @override
  String get noDefinition => 'Keine Definition gefunden.';

  @override
  String get translateInstead => 'Stattdessen übersetzen';

  @override
  String get definitionsCredit =>
      'Definitionen aus dem Wiktionary (CC BY-SA), auf Englisch.';

  @override
  String get translateInto => 'Nach:';

  @override
  String get alreadyInLanguage =>
      'Dieses Buch ist bereits in dieser Sprache. Wähle oben eine andere.';

  @override
  String get translationCredit =>
      'Übersetzungen von MyMemory. Der markierte Text wird an deren Dienst gesendet.';

  @override
  String get langAr => 'Arabisch';

  @override
  String get langZh => 'Chinesisch';

  @override
  String get langNl => 'Niederländisch';

  @override
  String get langEn => 'Englisch';

  @override
  String get langFr => 'Französisch';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langEl => 'Griechisch';

  @override
  String get langHe => 'Hebräisch';

  @override
  String get langHi => 'Hindi';

  @override
  String get langIt => 'Italienisch';

  @override
  String get langJa => 'Japanisch';

  @override
  String get langKo => 'Koreanisch';

  @override
  String get langPl => 'Polnisch';

  @override
  String get langPt => 'Portugiesisch';

  @override
  String get langRu => 'Russisch';

  @override
  String get langEs => 'Spanisch';

  @override
  String get langSv => 'Schwedisch';

  @override
  String get langTr => 'Türkisch';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get sameAsDevice => 'Wie auf dem Gerät';

  @override
  String get previewText =>
      'Es war die beste und die schlimmste aller Zeiten, ein Jahrhundert der Weisheit und des Unsinns.';

  @override
  String get sectionText => 'Text';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get fontDescSerif =>
      'Literata: eine Serifenschrift, entworfen fürs Lesen am Bildschirm.';

  @override
  String get fontDescGaramond =>
      'EB Garamond: eine klassische Buchschrift nach Vorbildern aus dem 16. Jahrhundert.';

  @override
  String get fontDescSans =>
      'Atkinson Hyperlegible: eine serifenlose Schrift des Braille Institute, bei der sich ähnliche Buchstaben leicht unterscheiden lassen.';

  @override
  String get fontDescDyslexic =>
      'OpenDyslexic hat schwerere Buchstabenunterkanten, damit Buchstaben nicht kippen oder vertauscht werden. Viele finden zudem mehr Buchstabenabstand und Flattersatz leichter lesbar.';

  @override
  String get textSize => 'Schriftgröße';

  @override
  String get lineSpacing => 'Zeilenabstand';

  @override
  String get letterSpacing => 'Buchstabenabstand';

  @override
  String get normal => 'Normal';

  @override
  String get justifyText => 'Blocksatz';

  @override
  String get justifySubtitle =>
      'Gerader rechter Rand. Ausschalten für gleichmäßige Wortabstände.';

  @override
  String get sectionPage => 'Seite';

  @override
  String get margins => 'Ränder';

  @override
  String get lineWidth => 'Zeilenbreite';

  @override
  String get lineWidthHint =>
      'Kürzere Zeilen lassen sich leichter verfolgen; die Textspalte ist nie breiter als der Bildschirm abzüglich der Ränder.';

  @override
  String get sectionScreen => 'Bildschirm';

  @override
  String get brightness => 'Helligkeit';

  @override
  String get warmth => 'Wärme';

  @override
  String get off => 'Aus';

  @override
  String get screenHint =>
      'Helligkeit und Wärme gelten für die ganze App, zusätzlich zu den Einstellungen deines Geräts. Wärme verringert blaues Licht, wie ein Nachtmodus.';

  @override
  String readingSpeed(int wpm) {
    return 'Lesegeschwindigkeit: etwa $wpm Wörter pro Minute (wird beim Lesen ermittelt).';
  }

  @override
  String get resetDefaults => 'Auf Standard zurücksetzen';

  @override
  String errCatalogHttp(int status) {
    return 'Der Katalog hat einen Fehler gemeldet ($status).';
  }

  @override
  String get errSearchFailed => 'Die Suche ist fehlgeschlagen.';

  @override
  String get errNoOtherEdition =>
      'Von diesem Buch gibt es keine andere Ausgabe.';

  @override
  String get errNoEpub =>
      'Zu diesem Titel gibt es keine E-Book-Ausgabe (vielleicht ist es ein Hörbuch).';

  @override
  String get errDownloadTimeout =>
      'Der Download hat zu lange gedauert. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String errDownloadHttp(int status) {
    return 'Der Download ist fehlgeschlagen ($status).';
  }

  @override
  String get errInvalidEpub =>
      'Die heruntergeladene Datei ist kein gültiges EPUB.';

  @override
  String get errWikisourceTooLong =>
      'Wikisource konnte dieses Buch nicht vorbereiten: Es ist zu lang für den EPUB-Dienst. Versuche einen einzelnen Band oder suche es in einem anderen Katalog.';

  @override
  String errDictionary(int status) {
    return 'Das Wörterbuch ist nicht verfügbar ($status).';
  }

  @override
  String errTranslationUnavailable(int status) {
    return 'Die Übersetzung ist nicht verfügbar ($status).';
  }

  @override
  String get errTranslationQuota =>
      'Das tägliche Limit für kostenlose Übersetzungen ist erreicht.';

  @override
  String errTranslationFailed(int status) {
    return 'Die Übersetzung ist fehlgeschlagen ($status).';
  }

  @override
  String errSourceBusy(String host) {
    return '$host ist ausgelastet; versuche es in einer Minute erneut.';
  }

  @override
  String errSourceHttp(String host, int status) {
    return '$host hat einen Fehler gemeldet ($status).';
  }

  @override
  String get errTimeout =>
      'Die Verbindung hat zu lange gedauert. Prüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get errGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String updateReady(String version) {
    return 'Illuminati $version ist bereit und wird beim Schließen der App installiert.';
  }

  @override
  String get updateReadyRestart => 'Jetzt neu starten';

  @override
  String updateAvailable(String version) {
    return 'Illuminati $version ist verfügbar.';
  }

  @override
  String get updateDownload => 'Herunterladen';
}
