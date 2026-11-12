// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class L10nFr extends L10n {
  L10nFr([String locale = 'fr']) : super(locale);

  @override
  String get cancel => 'Annuler';

  @override
  String get remove => 'Retirer';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get done => 'Terminé';

  @override
  String get create => 'Créer';

  @override
  String get rename => 'Renommer';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get back => 'Retour';

  @override
  String get undo => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get unknownAuthor => 'Auteur inconnu';

  @override
  String get about => 'À propos';

  @override
  String get displayAccessibility => 'Affichage et accessibilité';

  @override
  String get aboutText =>
      'Illuminati vous permet de trouver, télécharger et lire des livres qui n’ont jamais été protégés par le droit d’auteur ou dont les droits ont expiré.\n\nLes livres proviennent de Project Gutenberg (gutenberg.org), Standard Ebooks (standardebooks.org), Wikisource (wikisource.org, en EPUB créés par WS Export) et Internet Archive (archive.org). Ils sont dans le domaine public aux États-Unis, sauf certains textes de Wikisource placés sous licence libre. Le droit d’auteur varie selon les pays : vérifiez la législation de votre pays avant de télécharger.\n\nLes définitions viennent du Wiktionary et les traductions de MyMemory ; le texte sélectionné est envoyé à ces services.';

  @override
  String get discoverFreeBooks => 'Découvrir des livres gratuits';

  @override
  String get discoverSubtitle =>
      'Des classiques dont les droits ont expiré, à télécharger et garder gratuitement.';

  @override
  String get searchHint => 'Rechercher par titre ou auteur';

  @override
  String get catalogLanguage => 'Langue du catalogue';

  @override
  String get allLanguages => 'Toutes les langues';

  @override
  String get gutenbergSubtitle =>
      'La plus grande bibliothèque gratuite : plus de 75 000 livres du domaine public';

  @override
  String get noBooksFound => 'Aucun livre trouvé. Essayez une autre recherche.';

  @override
  String get catalogTimeout => 'Le catalogue met trop de temps à répondre.';

  @override
  String get catalogOffline =>
      'Impossible de charger le catalogue. Vérifiez votre connexion internet.';

  @override
  String couldNotReach(String source) {
    return 'Impossible de joindre $source.';
  }

  @override
  String get downloadFree => 'Télécharger gratuitement';

  @override
  String get yourLibrary => 'Votre bibliothèque';

  @override
  String libraryAndShelves(int count) {
    return 'Bibliothèque et étagères ($count)';
  }

  @override
  String get libraryEmptyHome =>
      'Votre bibliothèque est vide. Les livres que vous téléchargez depuis le catalogue apparaîtront ici, prêts à être lus hors ligne.';

  @override
  String noDownloadedSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Aucun livre téléchargé. Vos $count livres enregistrés se trouvent dans Bibliothèque et étagères.',
      one:
          'Aucun livre téléchargé. Votre livre enregistré se trouve dans Bibliothèque et étagères.',
    );
    return '$_temp0';
  }

  @override
  String get catPopular => 'Populaires';

  @override
  String get catFiction => 'Fiction';

  @override
  String get catMystery => 'Policier';

  @override
  String get catAdventure => 'Aventure';

  @override
  String get catScienceFiction => 'Science-fiction';

  @override
  String get catRomance => 'Romance';

  @override
  String get catHorror => 'Horreur';

  @override
  String get catFantasy => 'Fantasy';

  @override
  String get catChildren => 'Jeunesse';

  @override
  String get catPoetry => 'Poésie';

  @override
  String get catDrama => 'Théâtre';

  @override
  String get catPhilosophy => 'Philosophie';

  @override
  String get catHistory => 'Histoire';

  @override
  String get catScience => 'Sciences';

  @override
  String get catBiography => 'Biographie';

  @override
  String get taglineStandardEbooks =>
      'Des classiques soigneusement mis en page et relus';

  @override
  String get taglineWikisource =>
      'Des textes transcrits par des bénévoles, en de nombreuses langues';

  @override
  String get taglineArchive =>
      'Numérisations d’anciennes éditions imprimées (texte obtenu par OCR)';

  @override
  String rightsGutenberg(int id) {
    return 'Provient de Project Gutenberg (livre numérique n° $id). Ce livre est dans le domaine public aux États-Unis. Le droit d’auteur varie selon les pays : vérifiez la législation de votre pays avant de télécharger.';
  }

  @override
  String get rightsStandardEbooks =>
      'Provient de Standard Ebooks, dont les éditions sont dans le domaine public aux États-Unis et dont les propres modifications sont versées au domaine public (CC0). Le droit d’auteur varie selon les pays : vérifiez la législation de votre pays.';

  @override
  String get rightsWikisource =>
      'Provient de Wikisource, transcrit par des bénévoles ; l’EPUB est généré par WS Export. Wikisource héberge des textes du domaine public et certains sous licence libre (comme CC BY-SA), qui permettent de les lire et de les partager librement. Vérifiez la législation de votre pays.';

  @override
  String rightsArchive(String year) {
    return 'Provient d’Internet Archive. Seuls les livres publiés en $year ou avant sont proposés : ils sont donc dans le domaine public aux États-Unis. Le texte de l’EPUB a été créé automatiquement à partir de numérisations et peut contenir des erreurs. Le droit d’auteur varie selon les pays : vérifiez la législation de votre pays.';
  }

  @override
  String addedToLibrary(String title) {
    return '« $title » a été ajouté à votre bibliothèque';
  }

  @override
  String couldNotDownload(String title, String error) {
    return 'Impossible de télécharger « $title » : $error';
  }

  @override
  String get removeFromLibraryQuestion => 'Retirer de la bibliothèque ?';

  @override
  String removeFromLibraryBody(String title) {
    return '« $title » sera retiré de votre bibliothèque et de vos étagères, avec ses notes, surlignages et signets. Vous pourrez le télécharger de nouveau à tout moment.';
  }

  @override
  String get continueReading => 'Reprendre la lecture';

  @override
  String get readNow => 'Lire maintenant';

  @override
  String get downloading => 'Téléchargement…';

  @override
  String downloadingPercent(int percent) {
    return 'Téléchargement : $percent %';
  }

  @override
  String get noEbookEdition => 'Pas d’édition numérique';

  @override
  String get freeToRead => 'Lecture libre';

  @override
  String get publicDomain => 'Domaine public';

  @override
  String downloadsCount(String count) {
    return '$count téléchargements';
  }

  @override
  String get getIllustratedEdition => 'Obtenir l’édition illustrée';

  @override
  String get illustratedDownloaded => 'Édition illustrée téléchargée';

  @override
  String get removeDownload => 'Supprimer le téléchargement';

  @override
  String get removeFromLibrary => 'Retirer de la bibliothèque';

  @override
  String get aboutThisBook => 'À propos de ce livre';

  @override
  String get subjects => 'Sujets';

  @override
  String get wantToRead => 'À lire';

  @override
  String get finished => 'Terminé';

  @override
  String get addToShelf => 'Ajouter à une étagère';

  @override
  String onShelf(String name) {
    return 'Sur « $name »';
  }

  @override
  String onShelves(int count) {
    return 'Sur $count étagères';
  }

  @override
  String get newShelf => 'Nouvelle étagère';

  @override
  String get newShelfEllipsis => 'Nouvelle étagère…';

  @override
  String get shelfNameHint => 'p. ex. Favoris, Philosophie, À lire';

  @override
  String get renameShelf => 'Renommer l’étagère';

  @override
  String get deleteShelf => 'Supprimer l’étagère';

  @override
  String deleteShelfQuestion(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get deleteShelfBody =>
      'L’étagère est supprimée ; ses livres restent dans votre bibliothèque.';

  @override
  String get noShelvesYet =>
      'Vous n’avez pas encore d’étagère. Créez-en une pour regrouper vos livres comme vous le souhaitez.';

  @override
  String bookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres',
      one: '1 livre',
    );
    return '$_temp0';
  }

  @override
  String get bookDetails => 'Détails du livre';

  @override
  String get addToShelfEllipsis => 'Ajouter à une étagère…';

  @override
  String get removeFromWantToRead => 'Retirer de « À lire »';

  @override
  String get markNotFinished => 'Marquer comme non terminé';

  @override
  String get markFinished => 'Marquer comme terminé';

  @override
  String downloadRemoved(String title) {
    return 'Téléchargement supprimé. « $title » reste dans votre bibliothèque, avec vos notes et votre position.';
  }

  @override
  String get sort => 'Trier';

  @override
  String get filterHint => 'Filtrer par titre ou auteur';

  @override
  String get viewAll => 'Tous';

  @override
  String get viewDownloaded => 'Téléchargés';

  @override
  String get viewReading => 'En cours';

  @override
  String get shelfHint =>
      'Faites un clic droit ou un appui long sur une étagère pour la renommer ou la supprimer. Ajoutez des livres avec « Ajouter à une étagère » sur n’importe quel livre.';

  @override
  String noBooksMatch(String query) {
    return 'Aucun livre ne correspond à « $query ».';
  }

  @override
  String get emptyShelf =>
      'Cette étagère est vide.\nOuvrez un livre et choisissez « Ajouter à une étagère ».';

  @override
  String get emptyDownloaded => 'Aucun livre téléchargé.';

  @override
  String get emptyWantToRead =>
      'Rien pour l’instant.\nMarquez des livres du catalogue « À lire » ; ils sont enregistrés sans être téléchargés.';

  @override
  String get emptyReading => 'Vous n’avez aucun livre en cours.';

  @override
  String get emptyFinished => 'Les livres que vous terminez apparaissent ici.';

  @override
  String get emptyLibrary => 'Votre bibliothèque est vide.';

  @override
  String get sortRecent => 'Lus récemment';

  @override
  String get sortTitle => 'Titre';

  @override
  String get sortAuthor => 'Auteur';

  @override
  String get sortProgress => 'Progression';

  @override
  String get sortAdded => 'Ajoutés récemment';

  @override
  String get tileNew => 'Nouveau';

  @override
  String get notDownloaded => 'Non téléchargé';

  @override
  String get note => 'Note';

  @override
  String get writeNote => 'Écrivez une note…';

  @override
  String get removeHighlight => 'Retirer le surlignage';

  @override
  String get contents => 'Sommaire';

  @override
  String bookmarksCount(int count) {
    return 'Signets ($count)';
  }

  @override
  String notesCount(int count) {
    return 'Notes ($count)';
  }

  @override
  String get unknownChapter => 'Chapitre inconnu';

  @override
  String get noBookmarks =>
      'Pas encore de signet.\nUtilisez le bouton signet de la barre d’outils (ou Ctrl+B).';

  @override
  String get bookmark => 'Signet';

  @override
  String get deleteBookmark => 'Supprimer le signet';

  @override
  String get noHighlights =>
      'Pas encore de surlignage.\nSélectionnez du texte et choisissez Surligner ou Note. Sur un ordinateur, faites un clic droit sur la sélection.';

  @override
  String get copyAllMarkdown => 'Tout copier en Markdown';

  @override
  String get notesCopied => 'Notes copiées dans le presse-papiers';

  @override
  String get editNote => 'Modifier la note';

  @override
  String get addNote => 'Ajouter une note';

  @override
  String get editHighlight => 'Modifier le surlignage';

  @override
  String get highlight => 'Surligner';

  @override
  String get define => 'Définir';

  @override
  String get translate => 'Traduire';

  @override
  String get closeImage => 'Fermer l’image';

  @override
  String bookOpenError(String error) {
    return 'Impossible d’ouvrir ce livre.\n$error';
  }

  @override
  String get lessThanMinuteLeft =>
      'Moins d’une minute restante dans le chapitre';

  @override
  String minutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min restantes dans le chapitre',
      one: '1 min restante dans le chapitre',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutesLeft(int hours, int minutes) {
    return '$hours h $minutes min restantes dans le chapitre';
  }

  @override
  String finishedBook(String title) {
    return 'Vous avez terminé « $title ». Il figure maintenant dans votre liste des livres terminés.';
  }

  @override
  String get search => 'Rechercher';

  @override
  String searchNoMatches(String query) {
    return '« $query » · aucun résultat';
  }

  @override
  String searchPosition(String query, int index, int total) {
    return '« $query » · $index sur $total';
  }

  @override
  String get previousMatch => 'Résultat précédent';

  @override
  String get nextMatch => 'Résultat suivant (F3)';

  @override
  String get closeSearch => 'Fermer la recherche';

  @override
  String get theEnd => '— Fin —';

  @override
  String nextChapterTitle(String title) {
    return 'Suivant : $title';
  }

  @override
  String get backToLibrary => 'Retour à la bibliothèque';

  @override
  String get searchInBookShortcut => 'Rechercher dans le livre (Ctrl+F)';

  @override
  String get removeBookmarkShortcut => 'Retirer le signet (Ctrl+B)';

  @override
  String get bookmarkPageShortcut => 'Ajouter un signet à cette page (Ctrl+B)';

  @override
  String get contentsBookmarksNotes => 'Sommaire, signets et notes';

  @override
  String get displaySettings => 'Réglages d’affichage';

  @override
  String get previousChapter => 'Chapitre précédent';

  @override
  String get nextChapter => 'Chapitre suivant';

  @override
  String chapterStatus(String title, int index, int total, int percent) {
    return '$title  ·  Chapitre $index sur $total  ·  $percent % lu';
  }

  @override
  String get searchInThisBook => 'Rechercher dans ce livre';

  @override
  String get typeTwoLetters => 'Saisissez au moins deux lettres.';

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

  @override
  String matchesMany(int count) {
    return 'Plus de $count résultats';
  }

  @override
  String get translation => 'Traduction';

  @override
  String get noDefinition => 'Aucune définition trouvée.';

  @override
  String get translateInstead => 'Traduire plutôt';

  @override
  String get definitionsCredit =>
      'Définitions du Wiktionary (CC BY-SA), rédigées en anglais.';

  @override
  String get translateInto => 'En :';

  @override
  String get alreadyInLanguage =>
      'Ce livre est déjà dans cette langue. Choisissez-en une autre ci-dessus.';

  @override
  String get translationCredit =>
      'Traductions par MyMemory. Le texte sélectionné est envoyé à leur service.';

  @override
  String get langAr => 'Arabe';

  @override
  String get langZh => 'Chinois';

  @override
  String get langNl => 'Néerlandais';

  @override
  String get langEn => 'Anglais';

  @override
  String get langFr => 'Français';

  @override
  String get langDe => 'Allemand';

  @override
  String get langEl => 'Grec';

  @override
  String get langHe => 'Hébreu';

  @override
  String get langHi => 'Hindi';

  @override
  String get langIt => 'Italien';

  @override
  String get langJa => 'Japonais';

  @override
  String get langKo => 'Coréen';

  @override
  String get langPl => 'Polonais';

  @override
  String get langPt => 'Portugais';

  @override
  String get langRu => 'Russe';

  @override
  String get langEs => 'Espagnol';

  @override
  String get langSv => 'Suédois';

  @override
  String get langTr => 'Turc';

  @override
  String get appLanguage => 'Langue de l’application';

  @override
  String get sameAsDevice => 'Comme l’appareil';

  @override
  String get previewText =>
      'C’était le meilleur et le pire des temps, le siècle de la folie et celui de la sagesse.';

  @override
  String get sectionText => 'Texte';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSepia => 'Sépia';

  @override
  String get themeDark => 'Sombre';

  @override
  String get fontDescSerif =>
      'Literata : une police à empattements conçue pour la lecture à l’écran.';

  @override
  String get fontDescGaramond =>
      'EB Garamond : un caractère de livre classique, inspiré des fontes du XVIᵉ siècle.';

  @override
  String get fontDescSans =>
      'Atkinson Hyperlegible : une police sans empattements conçue par le Braille Institute pour que les lettres semblables se distinguent facilement.';

  @override
  String get fontDescDyslexic =>
      'OpenDyslexic alourdit le bas des lettres pour éviter qu’elles ne se retournent ou ne s’inversent. Beaucoup de lecteurs trouvent aussi la lecture plus facile avec plus d’espace entre les lettres et sans justification.';

  @override
  String get textSize => 'Taille du texte';

  @override
  String get lineSpacing => 'Interligne';

  @override
  String get letterSpacing => 'Espacement des lettres';

  @override
  String get normal => 'Normal';

  @override
  String get justifyText => 'Justifier le texte';

  @override
  String get justifySubtitle =>
      'Bord droit régulier. Désactivez pour des espaces réguliers entre les mots.';

  @override
  String get sectionPage => 'Page';

  @override
  String get margins => 'Marges';

  @override
  String get lineWidth => 'Largeur des lignes';

  @override
  String get lineWidthHint =>
      'Les lignes courtes sont plus faciles à suivre ; la colonne de texte n’est jamais plus large que l’écran moins les marges.';

  @override
  String get sectionScreen => 'Écran';

  @override
  String get brightness => 'Luminosité';

  @override
  String get warmth => 'Chaleur';

  @override
  String get off => 'Désactivée';

  @override
  String get screenHint =>
      'La luminosité et la chaleur s’appliquent à toute l’application, en plus des réglages de votre appareil. La chaleur réduit la lumière bleue, comme un mode nuit.';

  @override
  String readingSpeed(int wpm) {
    return 'Vitesse de lecture : environ $wpm mots par minute (apprise pendant que vous lisez).';
  }

  @override
  String get resetDefaults => 'Rétablir les valeurs par défaut';

  @override
  String errCatalogHttp(int status) {
    return 'Le catalogue a renvoyé une erreur ($status).';
  }

  @override
  String get errSearchFailed => 'La recherche a échoué.';

  @override
  String get errNoOtherEdition =>
      'Il n’existe pas d’autre édition de ce livre.';

  @override
  String get errNoEpub =>
      'Ce titre n’a pas d’édition numérique (il s’agit peut-être d’un livre audio).';

  @override
  String get errDownloadTimeout =>
      'Le téléchargement a pris trop de temps. Vérifiez votre connexion et réessayez.';

  @override
  String errDownloadHttp(int status) {
    return 'Le téléchargement a échoué ($status).';
  }

  @override
  String get errInvalidEpub =>
      'Le fichier téléchargé n’est pas un EPUB valide.';

  @override
  String get errWikisourceTooLong =>
      'Wikisource n’a pas pu préparer ce livre : il est trop long pour son service EPUB. Essayez l’un de ses volumes ou cherchez-le dans un autre catalogue.';

  @override
  String errDictionary(int status) {
    return 'Le dictionnaire n’est pas disponible ($status).';
  }

  @override
  String errTranslationUnavailable(int status) {
    return 'La traduction n’est pas disponible ($status).';
  }

  @override
  String get errTranslationQuota =>
      'La limite quotidienne de traductions gratuites est atteinte.';

  @override
  String errTranslationFailed(int status) {
    return 'La traduction a échoué ($status).';
  }

  @override
  String errSourceBusy(String host) {
    return '$host est occupé ; réessayez dans une minute.';
  }

  @override
  String errSourceHttp(String host, int status) {
    return '$host a renvoyé une erreur ($status).';
  }

  @override
  String get errTimeout =>
      'La connexion a pris trop de temps. Vérifiez votre connexion internet et réessayez.';

  @override
  String get errGeneric => 'Une erreur s’est produite. Veuillez réessayer.';

  @override
  String updateReady(String version) {
    return 'Illuminati $version est prêt. Il sera installé à la fermeture de l’application.';
  }

  @override
  String get updateReadyRestart => 'Redémarrer';

  @override
  String updateAvailable(String version) {
    return 'Illuminati $version est disponible.';
  }

  @override
  String get updateDownload => 'Télécharger';
}
