import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @unknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get unknownAuthor;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @displayAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Display & accessibility'**
  String get displayAccessibility;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Illuminati lets you find, download and read books that were never under copyright or whose copyright has expired.\n\nBooks come from Project Gutenberg (gutenberg.org), Standard Ebooks (standardebooks.org), Wikisource (wikisource.org, as EPUBs made by WS Export) and the Internet Archive (archive.org). They are in the public domain in the United States, except some Wikisource texts that are under free licences. Copyright terms differ between countries, so check your local laws before downloading.\n\nWord definitions come from Wiktionary and translations from MyMemory; the selected text is sent to those services.'**
  String get aboutText;

  /// No description provided for @discoverFreeBooks.
  ///
  /// In en, this message translates to:
  /// **'Discover free books'**
  String get discoverFreeBooks;

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Classics whose copyright has expired, free to download and keep.'**
  String get discoverSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title or author'**
  String get searchHint;

  /// No description provided for @catalogLanguage.
  ///
  /// In en, this message translates to:
  /// **'Catalog language'**
  String get catalogLanguage;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get allLanguages;

  /// No description provided for @gutenbergSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The largest free library: over 75,000 public-domain books'**
  String get gutenbergSubtitle;

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found. Try another search.'**
  String get noBooksFound;

  /// No description provided for @catalogTimeout.
  ///
  /// In en, this message translates to:
  /// **'The catalog is taking too long to respond.'**
  String get catalogTimeout;

  /// No description provided for @catalogOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not load the catalog. Check your internet connection.'**
  String get catalogOffline;

  /// No description provided for @couldNotReach.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach {source}.'**
  String couldNotReach(String source);

  /// No description provided for @downloadFree.
  ///
  /// In en, this message translates to:
  /// **'Download free'**
  String get downloadFree;

  /// No description provided for @yourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get yourLibrary;

  /// No description provided for @libraryAndShelves.
  ///
  /// In en, this message translates to:
  /// **'Library & shelves ({count})'**
  String libraryAndShelves(int count);

  /// No description provided for @libraryEmptyHome.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty. Books you download from the catalog below will appear here, ready to read offline.'**
  String get libraryEmptyHome;

  /// No description provided for @noDownloadedSaved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{No downloaded books. Your saved book is in Library & shelves.} other{No downloaded books. Your {count} saved books are in Library & shelves.}}'**
  String noDownloadedSaved(int count);

  /// No description provided for @catPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get catPopular;

  /// No description provided for @catFiction.
  ///
  /// In en, this message translates to:
  /// **'Fiction'**
  String get catFiction;

  /// No description provided for @catMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get catMystery;

  /// No description provided for @catAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get catAdventure;

  /// No description provided for @catScienceFiction.
  ///
  /// In en, this message translates to:
  /// **'Science Fiction'**
  String get catScienceFiction;

  /// No description provided for @catRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get catRomance;

  /// No description provided for @catHorror.
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get catHorror;

  /// No description provided for @catFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get catFantasy;

  /// No description provided for @catChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get catChildren;

  /// No description provided for @catPoetry.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get catPoetry;

  /// No description provided for @catDrama.
  ///
  /// In en, this message translates to:
  /// **'Drama'**
  String get catDrama;

  /// No description provided for @catPhilosophy.
  ///
  /// In en, this message translates to:
  /// **'Philosophy'**
  String get catPhilosophy;

  /// No description provided for @catHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get catHistory;

  /// No description provided for @catScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get catScience;

  /// No description provided for @catBiography.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get catBiography;

  /// No description provided for @taglineStandardEbooks.
  ///
  /// In en, this message translates to:
  /// **'Beautifully typeset, carefully proofread classics'**
  String get taglineStandardEbooks;

  /// No description provided for @taglineWikisource.
  ///
  /// In en, this message translates to:
  /// **'Volunteer-transcribed texts in many languages'**
  String get taglineWikisource;

  /// No description provided for @taglineArchive.
  ///
  /// In en, this message translates to:
  /// **'Scans of old printed editions (text made by OCR)'**
  String get taglineArchive;

  /// No description provided for @rightsGutenberg.
  ///
  /// In en, this message translates to:
  /// **'From Project Gutenberg (ebook #{id}). This book is in the public domain in the United States. Copyright terms differ between countries, so check your local laws before downloading.'**
  String rightsGutenberg(int id);

  /// No description provided for @rightsStandardEbooks.
  ///
  /// In en, this message translates to:
  /// **'From Standard Ebooks, whose editions are in the public domain in the United States and dedicated to the public domain (CC0) for their own changes. Copyright terms differ between countries, so check your local laws.'**
  String get rightsStandardEbooks;

  /// No description provided for @rightsWikisource.
  ///
  /// In en, this message translates to:
  /// **'From Wikisource, transcribed by volunteers; the EPUB is generated by WS Export. Wikisource hosts public-domain texts and some under free licences (such as CC BY-SA), which allow free reading and sharing. Check your local laws.'**
  String get rightsWikisource;

  /// No description provided for @rightsArchive.
  ///
  /// In en, this message translates to:
  /// **'From the Internet Archive. Only books published in {year} or earlier are listed, so they are in the public domain in the United States. The EPUB text was made automatically from page scans and may contain errors. Copyright terms differ between countries, so check your local laws.'**
  String rightsArchive(String year);

  /// No description provided for @addedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'“{title}” added to your library'**
  String addedToLibrary(String title);

  /// No description provided for @couldNotDownload.
  ///
  /// In en, this message translates to:
  /// **'Could not download “{title}”: {error}'**
  String couldNotDownload(String title, String error);

  /// No description provided for @removeFromLibraryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove from library?'**
  String get removeFromLibraryQuestion;

  /// No description provided for @removeFromLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed from your library and shelves, with its notes, highlights and bookmarks. You can download it again at any time.'**
  String removeFromLibraryBody(String title);

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @readNow.
  ///
  /// In en, this message translates to:
  /// **'Read now'**
  String get readNow;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloading;

  /// No description provided for @downloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String downloadingPercent(int percent);

  /// No description provided for @noEbookEdition.
  ///
  /// In en, this message translates to:
  /// **'No e-book edition'**
  String get noEbookEdition;

  /// No description provided for @freeToRead.
  ///
  /// In en, this message translates to:
  /// **'Free to read'**
  String get freeToRead;

  /// No description provided for @publicDomain.
  ///
  /// In en, this message translates to:
  /// **'Public domain'**
  String get publicDomain;

  /// No description provided for @downloadsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} downloads'**
  String downloadsCount(String count);

  /// No description provided for @getIllustratedEdition.
  ///
  /// In en, this message translates to:
  /// **'Get illustrated edition'**
  String get getIllustratedEdition;

  /// No description provided for @illustratedDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Illustrated edition downloaded'**
  String get illustratedDownloaded;

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get removeDownload;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get removeFromLibrary;

  /// No description provided for @aboutThisBook.
  ///
  /// In en, this message translates to:
  /// **'About this book'**
  String get aboutThisBook;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @wantToRead.
  ///
  /// In en, this message translates to:
  /// **'Want to read'**
  String get wantToRead;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @addToShelf.
  ///
  /// In en, this message translates to:
  /// **'Add to shelf'**
  String get addToShelf;

  /// No description provided for @onShelf.
  ///
  /// In en, this message translates to:
  /// **'On “{name}”'**
  String onShelf(String name);

  /// No description provided for @onShelves.
  ///
  /// In en, this message translates to:
  /// **'On {count} shelves'**
  String onShelves(int count);

  /// No description provided for @newShelf.
  ///
  /// In en, this message translates to:
  /// **'New shelf'**
  String get newShelf;

  /// No description provided for @newShelfEllipsis.
  ///
  /// In en, this message translates to:
  /// **'New shelf…'**
  String get newShelfEllipsis;

  /// No description provided for @shelfNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Favorites, Philosophy, To read'**
  String get shelfNameHint;

  /// No description provided for @renameShelf.
  ///
  /// In en, this message translates to:
  /// **'Rename shelf'**
  String get renameShelf;

  /// No description provided for @deleteShelf.
  ///
  /// In en, this message translates to:
  /// **'Delete shelf'**
  String get deleteShelf;

  /// No description provided for @deleteShelfQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteShelfQuestion(String name);

  /// No description provided for @deleteShelfBody.
  ///
  /// In en, this message translates to:
  /// **'The shelf is deleted; its books stay in your library.'**
  String get deleteShelfBody;

  /// No description provided for @noShelvesYet.
  ///
  /// In en, this message translates to:
  /// **'You have no shelves yet. Create one to group books any way you like.'**
  String get noShelvesYet;

  /// No description provided for @bookCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String bookCount(int count);

  /// No description provided for @bookDetails.
  ///
  /// In en, this message translates to:
  /// **'Book details'**
  String get bookDetails;

  /// No description provided for @addToShelfEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Add to shelf…'**
  String get addToShelfEllipsis;

  /// No description provided for @removeFromWantToRead.
  ///
  /// In en, this message translates to:
  /// **'Remove from Want to read'**
  String get removeFromWantToRead;

  /// No description provided for @markNotFinished.
  ///
  /// In en, this message translates to:
  /// **'Mark as not finished'**
  String get markNotFinished;

  /// No description provided for @markFinished.
  ///
  /// In en, this message translates to:
  /// **'Mark as finished'**
  String get markFinished;

  /// No description provided for @downloadRemoved.
  ///
  /// In en, this message translates to:
  /// **'Download removed. “{title}” stays in your library with your notes and place.'**
  String downloadRemoved(String title);

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @filterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by title or author'**
  String get filterHint;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get viewAll;

  /// No description provided for @viewDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get viewDownloaded;

  /// No description provided for @viewReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get viewReading;

  /// No description provided for @shelfHint.
  ///
  /// In en, this message translates to:
  /// **'Right-click or long-press a shelf to rename or delete it. Add books with “Add to shelf” on any book.'**
  String get shelfHint;

  /// No description provided for @noBooksMatch.
  ///
  /// In en, this message translates to:
  /// **'No books match “{query}”.'**
  String noBooksMatch(String query);

  /// No description provided for @emptyShelf.
  ///
  /// In en, this message translates to:
  /// **'This shelf is empty.\nOpen any book and choose “Add to shelf”.'**
  String get emptyShelf;

  /// No description provided for @emptyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'No downloaded books.'**
  String get emptyDownloaded;

  /// No description provided for @emptyWantToRead.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.\nMark books as “Want to read” from the catalog; they are saved without downloading.'**
  String get emptyWantToRead;

  /// No description provided for @emptyReading.
  ///
  /// In en, this message translates to:
  /// **'You are not in the middle of any book.'**
  String get emptyReading;

  /// No description provided for @emptyFinished.
  ///
  /// In en, this message translates to:
  /// **'Books you finish appear here.'**
  String get emptyFinished;

  /// No description provided for @emptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty.'**
  String get emptyLibrary;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently read'**
  String get sortRecent;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @sortAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get sortAuthor;

  /// No description provided for @sortProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get sortProgress;

  /// No description provided for @sortAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortAdded;

  /// No description provided for @tileNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get tileNew;

  /// No description provided for @notDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get notDownloaded;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @writeNote.
  ///
  /// In en, this message translates to:
  /// **'Write a note…'**
  String get writeNote;

  /// No description provided for @removeHighlight.
  ///
  /// In en, this message translates to:
  /// **'Remove highlight'**
  String get removeHighlight;

  /// No description provided for @contents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get contents;

  /// No description provided for @bookmarksCount.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks ({count})'**
  String bookmarksCount(int count);

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'Notes ({count})'**
  String notesCount(int count);

  /// No description provided for @unknownChapter.
  ///
  /// In en, this message translates to:
  /// **'Unknown chapter'**
  String get unknownChapter;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet.\nUse the bookmark button in the toolbar (or Ctrl+B).'**
  String get noBookmarks;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @deleteBookmark.
  ///
  /// In en, this message translates to:
  /// **'Delete bookmark'**
  String get deleteBookmark;

  /// No description provided for @noHighlights.
  ///
  /// In en, this message translates to:
  /// **'No highlights yet.\nSelect text and choose Highlight or Note. On a computer, right-click the selection.'**
  String get noHighlights;

  /// No description provided for @copyAllMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy all as Markdown'**
  String get copyAllMarkdown;

  /// No description provided for @notesCopied.
  ///
  /// In en, this message translates to:
  /// **'Notes copied to the clipboard'**
  String get notesCopied;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @editHighlight.
  ///
  /// In en, this message translates to:
  /// **'Edit highlight'**
  String get editHighlight;

  /// No description provided for @highlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get highlight;

  /// No description provided for @define.
  ///
  /// In en, this message translates to:
  /// **'Define'**
  String get define;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @closeImage.
  ///
  /// In en, this message translates to:
  /// **'Close image'**
  String get closeImage;

  /// No description provided for @bookOpenError.
  ///
  /// In en, this message translates to:
  /// **'This book could not be opened.\n{error}'**
  String bookOpenError(String error);

  /// No description provided for @lessThanMinuteLeft.
  ///
  /// In en, this message translates to:
  /// **'Less than a minute left in chapter'**
  String get lessThanMinuteLeft;

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 min left in chapter} other{{minutes} min left in chapter}}'**
  String minutesLeft(int minutes);

  /// No description provided for @hoursMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min left in chapter'**
  String hoursMinutesLeft(int hours, int minutes);

  /// No description provided for @finishedBook.
  ///
  /// In en, this message translates to:
  /// **'You finished “{title}”. It’s now on your Finished list.'**
  String finishedBook(String title);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'“{query}” · no matches'**
  String searchNoMatches(String query);

  /// No description provided for @searchPosition.
  ///
  /// In en, this message translates to:
  /// **'“{query}” · {index} of {total}'**
  String searchPosition(String query, int index, int total);

  /// No description provided for @previousMatch.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get previousMatch;

  /// No description provided for @nextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match (F3)'**
  String get nextMatch;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @theEnd.
  ///
  /// In en, this message translates to:
  /// **'— The End —'**
  String get theEnd;

  /// No description provided for @nextChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String nextChapterTitle(String title);

  /// No description provided for @backToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Back to library'**
  String get backToLibrary;

  /// No description provided for @searchInBookShortcut.
  ///
  /// In en, this message translates to:
  /// **'Search in book (Ctrl+F)'**
  String get searchInBookShortcut;

  /// No description provided for @removeBookmarkShortcut.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark (Ctrl+B)'**
  String get removeBookmarkShortcut;

  /// No description provided for @bookmarkPageShortcut.
  ///
  /// In en, this message translates to:
  /// **'Bookmark this page (Ctrl+B)'**
  String get bookmarkPageShortcut;

  /// No description provided for @contentsBookmarksNotes.
  ///
  /// In en, this message translates to:
  /// **'Contents, bookmarks & notes'**
  String get contentsBookmarksNotes;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display settings'**
  String get displaySettings;

  /// No description provided for @previousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get previousChapter;

  /// No description provided for @nextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get nextChapter;

  /// No description provided for @chapterStatus.
  ///
  /// In en, this message translates to:
  /// **'{title}  ·  Chapter {index} of {total}  ·  {percent}% read'**
  String chapterStatus(String title, int index, int total, int percent);

  /// No description provided for @searchInThisBook.
  ///
  /// In en, this message translates to:
  /// **'Search in this book'**
  String get searchInThisBook;

  /// No description provided for @typeTwoLetters.
  ///
  /// In en, this message translates to:
  /// **'Type at least two letters.'**
  String get typeTwoLetters;

  /// No description provided for @matchesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches} =1{1 match} other{{count} matches}}'**
  String matchesCount(int count);

  /// No description provided for @matchesMany.
  ///
  /// In en, this message translates to:
  /// **'{count}+ matches'**
  String matchesMany(int count);

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @noDefinition.
  ///
  /// In en, this message translates to:
  /// **'No definition found.'**
  String get noDefinition;

  /// No description provided for @translateInstead.
  ///
  /// In en, this message translates to:
  /// **'Translate instead'**
  String get translateInstead;

  /// No description provided for @definitionsCredit.
  ///
  /// In en, this message translates to:
  /// **'Definitions from Wiktionary (CC BY-SA), written in English.'**
  String get definitionsCredit;

  /// No description provided for @translateInto.
  ///
  /// In en, this message translates to:
  /// **'Into:'**
  String get translateInto;

  /// No description provided for @alreadyInLanguage.
  ///
  /// In en, this message translates to:
  /// **'This book is already in that language. Choose another one above.'**
  String get alreadyInLanguage;

  /// No description provided for @translationCredit.
  ///
  /// In en, this message translates to:
  /// **'Translations by MyMemory. Selected text is sent to their service.'**
  String get translationCredit;

  /// No description provided for @langAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langAr;

  /// No description provided for @langZh.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get langZh;

  /// No description provided for @langNl.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get langNl;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langFr.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get langFr;

  /// No description provided for @langDe.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get langDe;

  /// No description provided for @langEl.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get langEl;

  /// No description provided for @langHe.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get langHe;

  /// No description provided for @langHi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get langHi;

  /// No description provided for @langIt.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get langIt;

  /// No description provided for @langJa.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get langJa;

  /// No description provided for @langKo.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get langKo;

  /// No description provided for @langPl.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get langPl;

  /// No description provided for @langPt.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get langPt;

  /// No description provided for @langRu.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get langRu;

  /// No description provided for @langEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langEs;

  /// No description provided for @langSv.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get langSv;

  /// No description provided for @langTr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get langTr;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @sameAsDevice.
  ///
  /// In en, this message translates to:
  /// **'Same as device'**
  String get sameAsDevice;

  /// No description provided for @previewText.
  ///
  /// In en, this message translates to:
  /// **'It was the best of times, it was the worst of times; it was the age of wisdom, it was the age of foolishness.'**
  String get previewText;

  /// No description provided for @sectionText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get sectionText;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSepia;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @fontDescSerif.
  ///
  /// In en, this message translates to:
  /// **'Literata: a serif designed for reading on screens.'**
  String get fontDescSerif;

  /// No description provided for @fontDescGaramond.
  ///
  /// In en, this message translates to:
  /// **'EB Garamond: a classic book face, based on 16th-century type.'**
  String get fontDescGaramond;

  /// No description provided for @fontDescSans.
  ///
  /// In en, this message translates to:
  /// **'Atkinson Hyperlegible: a sans-serif designed by the Braille Institute so that similar letters are easy to tell apart.'**
  String get fontDescSans;

  /// No description provided for @fontDescDyslexic.
  ///
  /// In en, this message translates to:
  /// **'OpenDyslexic has weighted letter bottoms to help keep letters from flipping or swapping. Many readers also find extra letter spacing and unjustified text easier.'**
  String get fontDescDyslexic;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @lineSpacing.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get lineSpacing;

  /// No description provided for @letterSpacing.
  ///
  /// In en, this message translates to:
  /// **'Letter spacing'**
  String get letterSpacing;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @justifyText.
  ///
  /// In en, this message translates to:
  /// **'Justify text'**
  String get justifyText;

  /// No description provided for @justifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Even right edge. Turn off for even spacing between words.'**
  String get justifySubtitle;

  /// No description provided for @sectionPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get sectionPage;

  /// No description provided for @margins.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get margins;

  /// No description provided for @lineWidth.
  ///
  /// In en, this message translates to:
  /// **'Line width'**
  String get lineWidth;

  /// No description provided for @lineWidthHint.
  ///
  /// In en, this message translates to:
  /// **'Shorter lines are easier to follow; the text column is never wider than the screen minus the margins.'**
  String get lineWidthHint;

  /// No description provided for @sectionScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get sectionScreen;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @warmth.
  ///
  /// In en, this message translates to:
  /// **'Warmth'**
  String get warmth;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @screenHint.
  ///
  /// In en, this message translates to:
  /// **'Brightness and warmth apply to the whole app, on top of your device’s own settings. Warmth reduces blue light, like a night light.'**
  String get screenHint;

  /// No description provided for @readingSpeed.
  ///
  /// In en, this message translates to:
  /// **'Reading speed: about {wpm} words per minute (learned as you read).'**
  String readingSpeed(int wpm);

  /// No description provided for @resetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetDefaults;

  /// No description provided for @errCatalogHttp.
  ///
  /// In en, this message translates to:
  /// **'The catalog returned an error ({status}).'**
  String errCatalogHttp(int status);

  /// No description provided for @errSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed.'**
  String get errSearchFailed;

  /// No description provided for @errNoOtherEdition.
  ///
  /// In en, this message translates to:
  /// **'There is no other edition of this book.'**
  String get errNoOtherEdition;

  /// No description provided for @errNoEpub.
  ///
  /// In en, this message translates to:
  /// **'This title has no e-book edition (it may be an audio book).'**
  String get errNoEpub;

  /// No description provided for @errDownloadTimeout.
  ///
  /// In en, this message translates to:
  /// **'The download took too long. Check your connection and try again.'**
  String get errDownloadTimeout;

  /// No description provided for @errDownloadHttp.
  ///
  /// In en, this message translates to:
  /// **'Download failed ({status}).'**
  String errDownloadHttp(int status);

  /// No description provided for @errInvalidEpub.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file is not a valid EPUB.'**
  String get errInvalidEpub;

  /// No description provided for @errWikisourceTooLong.
  ///
  /// In en, this message translates to:
  /// **'Wikisource could not prepare this book: it is too long for their EPUB service. Try one of its volumes, or look for it in another catalog.'**
  String get errWikisourceTooLong;

  /// No description provided for @errDictionary.
  ///
  /// In en, this message translates to:
  /// **'The dictionary is unavailable ({status}).'**
  String errDictionary(int status);

  /// No description provided for @errTranslationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Translation is unavailable ({status}).'**
  String errTranslationUnavailable(int status);

  /// No description provided for @errTranslationQuota.
  ///
  /// In en, this message translates to:
  /// **'The free daily translation limit has been reached.'**
  String get errTranslationQuota;

  /// No description provided for @errTranslationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed ({status}).'**
  String errTranslationFailed(int status);

  /// No description provided for @errSourceBusy.
  ///
  /// In en, this message translates to:
  /// **'{host} is busy; try again in a minute.'**
  String errSourceBusy(String host);

  /// No description provided for @errSourceHttp.
  ///
  /// In en, this message translates to:
  /// **'{host} returned an error ({status}).'**
  String errSourceHttp(String host, int status);

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection took too long. Check your internet connection and try again.'**
  String get errTimeout;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'Illuminati {version} is ready. It will be installed when you close the app.'**
  String updateReady(String version);

  /// No description provided for @updateReadyRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get updateReadyRestart;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Illuminati {version} is available.'**
  String updateAvailable(String version);

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return L10nDe();
    case 'en':
      return L10nEn();
    case 'es':
      return L10nEs();
    case 'fr':
      return L10nFr();
    case 'it':
      return L10nIt();
    case 'pt':
      return L10nPt();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
