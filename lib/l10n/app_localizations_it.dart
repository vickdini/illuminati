// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class L10nIt extends L10n {
  L10nIt([String locale = 'it']) : super(locale);

  @override
  String get cancel => 'Annulla';

  @override
  String get remove => 'Rimuovi';

  @override
  String get delete => 'Elimina';

  @override
  String get save => 'Salva';

  @override
  String get done => 'Fatto';

  @override
  String get create => 'Crea';

  @override
  String get rename => 'Rinomina';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get back => 'Indietro';

  @override
  String get undo => 'Annulla';

  @override
  String get close => 'Chiudi';

  @override
  String get unknownAuthor => 'Autore sconosciuto';

  @override
  String get about => 'Informazioni';

  @override
  String get displayAccessibility => 'Schermo e accessibilità';

  @override
  String get aboutText =>
      'Illuminati ti permette di trovare, scaricare e leggere libri che non sono mai stati protetti dal diritto d’autore o i cui diritti sono scaduti.\n\nI libri provengono da Project Gutenberg (gutenberg.org), Standard Ebooks (standardebooks.org), Wikisource (wikisource.org, come EPUB creati da WS Export) e Internet Archive (archive.org). Sono di pubblico dominio negli Stati Uniti, tranne alcuni testi di Wikisource con licenze libere. Il diritto d’autore varia da paese a paese: controlla le leggi del tuo paese prima di scaricare.\n\nLe definizioni provengono da Wiktionary e le traduzioni da MyMemory; il testo selezionato viene inviato a questi servizi.';

  @override
  String get discoverFreeBooks => 'Scopri libri gratuiti';

  @override
  String get discoverSubtitle =>
      'Classici i cui diritti d’autore sono scaduti, da scaricare e conservare gratis.';

  @override
  String get searchHint => 'Cerca per titolo o autore';

  @override
  String get catalogLanguage => 'Lingua del catalogo';

  @override
  String get allLanguages => 'Tutte le lingue';

  @override
  String get gutenbergSubtitle =>
      'La più grande biblioteca gratuita: oltre 75.000 libri di pubblico dominio';

  @override
  String get noBooksFound => 'Nessun libro trovato. Prova un’altra ricerca.';

  @override
  String get catalogTimeout => 'Il catalogo impiega troppo tempo a rispondere.';

  @override
  String get catalogOffline =>
      'Impossibile caricare il catalogo. Controlla la connessione a internet.';

  @override
  String couldNotReach(String source) {
    return 'Impossibile raggiungere $source.';
  }

  @override
  String get downloadFree => 'Scarica gratis';

  @override
  String get yourLibrary => 'La tua biblioteca';

  @override
  String libraryAndShelves(int count) {
    return 'Biblioteca e scaffali ($count)';
  }

  @override
  String get libraryEmptyHome =>
      'La tua biblioteca è vuota. I libri che scarichi dal catalogo appariranno qui, pronti da leggere offline.';

  @override
  String noDownloadedSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nessun libro scaricato. I tuoi $count libri salvati sono in Biblioteca e scaffali.',
      one:
          'Nessun libro scaricato. Il tuo libro salvato è in Biblioteca e scaffali.',
    );
    return '$_temp0';
  }

  @override
  String get catPopular => 'Popolari';

  @override
  String get catFiction => 'Narrativa';

  @override
  String get catMystery => 'Gialli';

  @override
  String get catAdventure => 'Avventura';

  @override
  String get catScienceFiction => 'Fantascienza';

  @override
  String get catRomance => 'Romanzi rosa';

  @override
  String get catHorror => 'Horror';

  @override
  String get catFantasy => 'Fantasy';

  @override
  String get catChildren => 'Per ragazzi';

  @override
  String get catPoetry => 'Poesia';

  @override
  String get catDrama => 'Teatro';

  @override
  String get catPhilosophy => 'Filosofia';

  @override
  String get catHistory => 'Storia';

  @override
  String get catScience => 'Scienza';

  @override
  String get catBiography => 'Biografie';

  @override
  String get taglineStandardEbooks =>
      'Classici impaginati con cura e revisionati con attenzione';

  @override
  String get taglineWikisource =>
      'Testi trascritti da volontari in molte lingue';

  @override
  String get taglineArchive =>
      'Scansioni di vecchie edizioni a stampa (testo ottenuto con OCR)';

  @override
  String rightsGutenberg(int id) {
    return 'Da Project Gutenberg (ebook n. $id). Questo libro è di pubblico dominio negli Stati Uniti. Il diritto d’autore varia da paese a paese: controlla le leggi del tuo paese prima di scaricare.';
  }

  @override
  String get rightsStandardEbooks =>
      'Da Standard Ebooks, le cui edizioni sono di pubblico dominio negli Stati Uniti e che rilascia le proprie modifiche nel pubblico dominio (CC0). Il diritto d’autore varia da paese a paese: controlla le leggi del tuo paese.';

  @override
  String get rightsWikisource =>
      'Da Wikisource, trascritto da volontari; l’EPUB è generato da WS Export. Wikisource ospita testi di pubblico dominio e alcuni con licenze libere (come CC BY-SA), che consentono di leggerli e condividerli liberamente. Controlla le leggi del tuo paese.';

  @override
  String rightsArchive(String year) {
    return 'Da Internet Archive. Sono elencati solo libri pubblicati nel $year o prima, quindi di pubblico dominio negli Stati Uniti. Il testo dell’EPUB è stato creato automaticamente dalle scansioni e può contenere errori. Il diritto d’autore varia da paese a paese: controlla le leggi del tuo paese.';
  }

  @override
  String addedToLibrary(String title) {
    return '«$title» aggiunto alla tua biblioteca';
  }

  @override
  String couldNotDownload(String title, String error) {
    return 'Impossibile scaricare «$title»: $error';
  }

  @override
  String get removeFromLibraryQuestion => 'Rimuovere dalla biblioteca?';

  @override
  String removeFromLibraryBody(String title) {
    return '«$title» verrà rimosso dalla tua biblioteca e dai tuoi scaffali, insieme a note, evidenziazioni e segnalibri. Puoi scaricarlo di nuovo in qualsiasi momento.';
  }

  @override
  String get continueReading => 'Continua a leggere';

  @override
  String get readNow => 'Leggi ora';

  @override
  String get downloading => 'Download in corso…';

  @override
  String downloadingPercent(int percent) {
    return 'Download in corso: $percent%';
  }

  @override
  String get noEbookEdition => 'Nessuna edizione ebook';

  @override
  String get freeToRead => 'Lettura libera';

  @override
  String get publicDomain => 'Pubblico dominio';

  @override
  String downloadsCount(String count) {
    return '$count download';
  }

  @override
  String get getIllustratedEdition => 'Scarica l’edizione illustrata';

  @override
  String get illustratedDownloaded => 'Edizione illustrata scaricata';

  @override
  String get removeDownload => 'Rimuovi il download';

  @override
  String get removeFromLibrary => 'Rimuovi dalla biblioteca';

  @override
  String get aboutThisBook => 'Informazioni sul libro';

  @override
  String get subjects => 'Argomenti';

  @override
  String get wantToRead => 'Da leggere';

  @override
  String get finished => 'Letto';

  @override
  String get addToShelf => 'Aggiungi a uno scaffale';

  @override
  String onShelf(String name) {
    return 'In «$name»';
  }

  @override
  String onShelves(int count) {
    return 'In $count scaffali';
  }

  @override
  String get newShelf => 'Nuovo scaffale';

  @override
  String get newShelfEllipsis => 'Nuovo scaffale…';

  @override
  String get shelfNameHint => 'es. Preferiti, Filosofia, Da leggere';

  @override
  String get renameShelf => 'Rinomina scaffale';

  @override
  String get deleteShelf => 'Elimina scaffale';

  @override
  String deleteShelfQuestion(String name) {
    return 'Eliminare «$name»?';
  }

  @override
  String get deleteShelfBody =>
      'Lo scaffale viene eliminato; i suoi libri restano nella tua biblioteca.';

  @override
  String get noShelvesYet =>
      'Non hai ancora scaffali. Creane uno per raggruppare i libri come preferisci.';

  @override
  String bookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libri',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String get bookDetails => 'Dettagli del libro';

  @override
  String get addToShelfEllipsis => 'Aggiungi a uno scaffale…';

  @override
  String get removeFromWantToRead => 'Rimuovi da «Da leggere»';

  @override
  String get markNotFinished => 'Segna come non letto';

  @override
  String get markFinished => 'Segna come letto';

  @override
  String downloadRemoved(String title) {
    return 'Download rimosso. «$title» resta nella tua biblioteca con le tue note e la posizione di lettura.';
  }

  @override
  String get sort => 'Ordina';

  @override
  String get filterHint => 'Filtra per titolo o autore';

  @override
  String get viewAll => 'Tutti';

  @override
  String get viewDownloaded => 'Scaricati';

  @override
  String get viewReading => 'In lettura';

  @override
  String get shelfHint =>
      'Fai clic destro o tieni premuto su uno scaffale per rinominarlo o eliminarlo. Aggiungi libri con «Aggiungi a uno scaffale» su qualsiasi libro.';

  @override
  String noBooksMatch(String query) {
    return 'Nessun libro corrisponde a «$query».';
  }

  @override
  String get emptyShelf =>
      'Questo scaffale è vuoto.\nApri un libro e scegli «Aggiungi a uno scaffale».';

  @override
  String get emptyDownloaded => 'Nessun libro scaricato.';

  @override
  String get emptyWantToRead =>
      'Ancora niente qui.\nSegna i libri del catalogo come «Da leggere»: vengono salvati senza scaricarli.';

  @override
  String get emptyReading => 'Non stai leggendo nessun libro.';

  @override
  String get emptyFinished => 'Qui compaiono i libri che hai finito.';

  @override
  String get emptyLibrary => 'La tua biblioteca è vuota.';

  @override
  String get sortRecent => 'Letti di recente';

  @override
  String get sortTitle => 'Titolo';

  @override
  String get sortAuthor => 'Autore';

  @override
  String get sortProgress => 'Avanzamento';

  @override
  String get sortAdded => 'Aggiunti di recente';

  @override
  String get tileNew => 'Nuovo';

  @override
  String get notDownloaded => 'Non scaricato';

  @override
  String get note => 'Nota';

  @override
  String get writeNote => 'Scrivi una nota…';

  @override
  String get removeHighlight => 'Rimuovi evidenziazione';

  @override
  String get contents => 'Indice';

  @override
  String bookmarksCount(int count) {
    return 'Segnalibri ($count)';
  }

  @override
  String notesCount(int count) {
    return 'Note ($count)';
  }

  @override
  String get unknownChapter => 'Capitolo sconosciuto';

  @override
  String get noBookmarks =>
      'Ancora nessun segnalibro.\nUsa il pulsante segnalibro nella barra degli strumenti (o Ctrl+B).';

  @override
  String get bookmark => 'Segnalibro';

  @override
  String get deleteBookmark => 'Elimina segnalibro';

  @override
  String get noHighlights =>
      'Ancora nessuna evidenziazione.\nSeleziona del testo e scegli Evidenzia o Nota. Su un computer, fai clic destro sulla selezione.';

  @override
  String get copyAllMarkdown => 'Copia tutto in Markdown';

  @override
  String get notesCopied => 'Note copiate negli appunti';

  @override
  String get editNote => 'Modifica nota';

  @override
  String get addNote => 'Aggiungi nota';

  @override
  String get editHighlight => 'Modifica evidenziazione';

  @override
  String get highlight => 'Evidenzia';

  @override
  String get define => 'Definisci';

  @override
  String get translate => 'Traduci';

  @override
  String get closeImage => 'Chiudi immagine';

  @override
  String bookOpenError(String error) {
    return 'Impossibile aprire questo libro.\n$error';
  }

  @override
  String get lessThanMinuteLeft => 'Meno di un minuto alla fine del capitolo';

  @override
  String minutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min alla fine del capitolo',
      one: '1 min alla fine del capitolo',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutesLeft(int hours, int minutes) {
    return '$hours h $minutes min alla fine del capitolo';
  }

  @override
  String finishedBook(String title) {
    return 'Hai finito «$title». Ora è nell’elenco dei libri letti.';
  }

  @override
  String get search => 'Cerca';

  @override
  String searchNoMatches(String query) {
    return '«$query» · nessun risultato';
  }

  @override
  String searchPosition(String query, int index, int total) {
    return '«$query» · $index di $total';
  }

  @override
  String get previousMatch => 'Risultato precedente';

  @override
  String get nextMatch => 'Risultato successivo (F3)';

  @override
  String get closeSearch => 'Chiudi ricerca';

  @override
  String get theEnd => '— Fine —';

  @override
  String nextChapterTitle(String title) {
    return 'Successivo: $title';
  }

  @override
  String get backToLibrary => 'Torna alla biblioteca';

  @override
  String get searchInBookShortcut => 'Cerca nel libro (Ctrl+F)';

  @override
  String get removeBookmarkShortcut => 'Rimuovi segnalibro (Ctrl+B)';

  @override
  String get bookmarkPageShortcut =>
      'Aggiungi segnalibro a questa pagina (Ctrl+B)';

  @override
  String get contentsBookmarksNotes => 'Indice, segnalibri e note';

  @override
  String get displaySettings => 'Impostazioni di visualizzazione';

  @override
  String get previousChapter => 'Capitolo precedente';

  @override
  String get nextChapter => 'Capitolo successivo';

  @override
  String chapterStatus(String title, int index, int total, int percent) {
    return '$title  ·  Capitolo $index di $total  ·  $percent% letto';
  }

  @override
  String get searchInThisBook => 'Cerca in questo libro';

  @override
  String get typeTwoLetters => 'Digita almeno due lettere.';

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
      zero: 'Nessun risultato',
    );
    return '$_temp0';
  }

  @override
  String matchesMany(int count) {
    return 'Oltre $count risultati';
  }

  @override
  String get translation => 'Traduzione';

  @override
  String get noDefinition => 'Nessuna definizione trovata.';

  @override
  String get translateInstead => 'Traduci invece';

  @override
  String get definitionsCredit =>
      'Definizioni da Wiktionary (CC BY-SA), in inglese.';

  @override
  String get translateInto => 'In:';

  @override
  String get alreadyInLanguage =>
      'Questo libro è già in quella lingua. Scegline un’altra qui sopra.';

  @override
  String get translationCredit =>
      'Traduzioni di MyMemory. Il testo selezionato viene inviato al loro servizio.';

  @override
  String get langAr => 'Arabo';

  @override
  String get langZh => 'Cinese';

  @override
  String get langNl => 'Olandese';

  @override
  String get langEn => 'Inglese';

  @override
  String get langFr => 'Francese';

  @override
  String get langDe => 'Tedesco';

  @override
  String get langEl => 'Greco';

  @override
  String get langHe => 'Ebraico';

  @override
  String get langHi => 'Hindi';

  @override
  String get langIt => 'Italiano';

  @override
  String get langJa => 'Giapponese';

  @override
  String get langKo => 'Coreano';

  @override
  String get langPl => 'Polacco';

  @override
  String get langPt => 'Portoghese';

  @override
  String get langRu => 'Russo';

  @override
  String get langEs => 'Spagnolo';

  @override
  String get langSv => 'Svedese';

  @override
  String get langTr => 'Turco';

  @override
  String get appLanguage => 'Lingua dell’app';

  @override
  String get sameAsDevice => 'Come il dispositivo';

  @override
  String get previewText =>
      'Era il tempo migliore e il tempo peggiore, l’età della saggezza e l’età della follia.';

  @override
  String get sectionText => 'Testo';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeSepia => 'Seppia';

  @override
  String get themeDark => 'Scuro';

  @override
  String get fontDescSerif =>
      'Literata: un carattere con grazie pensato per la lettura su schermo.';

  @override
  String get fontDescGaramond =>
      'EB Garamond: un classico carattere da libro, ispirato ai caratteri del Cinquecento.';

  @override
  String get fontDescSans =>
      'Atkinson Hyperlegible: un carattere senza grazie creato dal Braille Institute perché le lettere simili si distinguano facilmente.';

  @override
  String get fontDescDyslexic =>
      'OpenDyslexic appesantisce la base delle lettere per evitare che si capovolgano o si scambino. Molti lettori trovano utili anche più spazio tra le lettere e il testo non giustificato.';

  @override
  String get textSize => 'Dimensione del testo';

  @override
  String get lineSpacing => 'Interlinea';

  @override
  String get letterSpacing => 'Spaziatura tra le lettere';

  @override
  String get normal => 'Normale';

  @override
  String get justifyText => 'Giustifica il testo';

  @override
  String get justifySubtitle =>
      'Margine destro allineato. Disattiva per spazi uguali tra le parole.';

  @override
  String get sectionPage => 'Pagina';

  @override
  String get margins => 'Margini';

  @override
  String get lineWidth => 'Larghezza delle righe';

  @override
  String get lineWidthHint =>
      'Le righe più corte si seguono più facilmente; la colonna di testo non è mai più larga dello schermo meno i margini.';

  @override
  String get sectionScreen => 'Schermo';

  @override
  String get brightness => 'Luminosità';

  @override
  String get warmth => 'Calore';

  @override
  String get off => 'Disattivato';

  @override
  String get screenHint =>
      'Luminosità e calore valgono per tutta l’app, oltre alle impostazioni del dispositivo. Il calore riduce la luce blu, come una modalità notturna.';

  @override
  String readingSpeed(int wpm) {
    return 'Velocità di lettura: circa $wpm parole al minuto (calcolata mentre leggi).';
  }

  @override
  String get resetDefaults => 'Ripristina predefiniti';

  @override
  String errCatalogHttp(int status) {
    return 'Il catalogo ha restituito un errore ($status).';
  }

  @override
  String get errSearchFailed => 'La ricerca non è riuscita.';

  @override
  String get errNoOtherEdition =>
      'Non esiste un’altra edizione di questo libro.';

  @override
  String get errNoEpub =>
      'Questo titolo non ha un’edizione ebook (potrebbe essere un audiolibro).';

  @override
  String get errDownloadTimeout =>
      'Il download ha richiesto troppo tempo. Controlla la connessione e riprova.';

  @override
  String errDownloadHttp(int status) {
    return 'Download non riuscito ($status).';
  }

  @override
  String get errInvalidEpub => 'Il file scaricato non è un EPUB valido.';

  @override
  String get errWikisourceTooLong =>
      'Wikisource non è riuscito a preparare questo libro: è troppo lungo per il suo servizio EPUB. Prova uno dei suoi volumi o cercalo in un altro catalogo.';

  @override
  String errDictionary(int status) {
    return 'Il dizionario non è disponibile ($status).';
  }

  @override
  String errTranslationUnavailable(int status) {
    return 'La traduzione non è disponibile ($status).';
  }

  @override
  String get errTranslationQuota =>
      'È stato raggiunto il limite giornaliero di traduzioni gratuite.';

  @override
  String errTranslationFailed(int status) {
    return 'Traduzione non riuscita ($status).';
  }

  @override
  String errSourceBusy(String host) {
    return '$host è occupato; riprova tra un minuto.';
  }

  @override
  String errSourceHttp(String host, int status) {
    return '$host ha restituito un errore ($status).';
  }

  @override
  String get errTimeout =>
      'La connessione ha richiesto troppo tempo. Controlla la connessione a internet e riprova.';

  @override
  String get errGeneric => 'Qualcosa è andato storto. Riprova.';
}
