# Illuminati

An e-reader for Windows, macOS, Linux and Android. It works like the Kindle app,
but its whole catalog is free: books that were never under copyright or whose
copyright has expired.

- **Your library** (top): books you have downloaded, most recently read first,
  with reading progress. Long-press or right-click a book to remove it.
- **Discover free books** (below): a row for each extra free catalog, then the
  Project Gutenberg catalog, sorted by popularity:
  - **Standard Ebooks**: carefully proofread and typeset editions (English).
  - **Wikisource**: volunteer transcriptions in many languages; EPUBs are built
    on demand by WS Export (very long multi-volume works may fail).
  - **Internet Archive**: scans of old printed books, limited to editions
    published 95+ years ago (US public domain); text is made by OCR.

  The search box, language and category apply to every row; a row is hidden
  when its source has nothing for the current language or category. Tap a
  book for details and a one-tap download. Gutenberg search matches any part
  of a title or author name and ignores accents ("miserab", "misérable" → *Los miserables*),
  using an offline copy of the full catalog that refreshes weekly.
- **Reader**: pages turn by tapping the left or right edge, with the arrow keys,
  or with Space/PageUp/PageDown. Tap the middle for the toolbar: search,
  bookmark, contents, chapter slider, and display settings (light/sepia/dark,
  serif/sans, text size, line spacing). Your place is saved automatically.
  - **Minutes left in chapter**, based on a reading speed the app learns as you read.
  - **Highlights, notes and bookmarks**: select text (long-press on phones; drag or
    double-click, then right-click, on computers) and choose Highlight or Note.
    Everything is listed in the side panel and can be copied as Markdown.
  - **Dictionary and translation**: select a word and choose Define (Wiktionary)
    or Translate (MyMemory). Both need an internet connection.
  - **Search inside the book** (Ctrl+F; F3 for the next match), ignoring case and accents.
  - **Images**: illustrations display inline; click or tap one to zoom.

  Keyboard: ←/→ or PageUp/PageDown turn pages, ↑/↓ scroll, Ctrl+F search,
  Ctrl+B bookmark, Esc closes search/toolbar or goes back.

## Run

```sh
flutter pub get
flutter run -d windows      # or: macos, linux, or an Android device id
flutter test
```

Release builds: `flutter build windows | macos | linux | apk | appbundle`.
macOS builds need a Mac and Linux builds need Linux; Windows and Android
build on this machine.

## How it works

| Piece | File |
|---|---|
| Catalog client (Gutenberg OPDS feed: search, subjects, languages, details) | `lib/services/catalog_service.dart` |
| Extra catalogs (Standard Ebooks, Wikisource, Internet Archive) | `lib/sources/` |
| Downloads, local storage (`library.json`), reading progress | `lib/services/library_service.dart` |
| EPUB → chapters/paragraphs (runs on a background isolate) | `lib/services/epub_parser.dart` |
| Offline title index (Gutenberg `pg_catalog.csv`, partial/accent-insensitive search) | `lib/services/title_index.dart` |
| Highlights, notes, bookmarks (`notes/<id>.json`, re-anchored by text) | `lib/models/annotation.dart` |
| Dictionary (Wiktionary) and translation (MyMemory) | `lib/services/lookup_service.dart` |
| In-book search | `lib/services/book_search.dart` |
| Reader preferences (`settings.json`) | `lib/services/settings_service.dart` |
| Home screen (library row + catalog grid) | `lib/screens/home_screen.dart` |
| Reader | `lib/screens/reader_screen.dart` |

Books and covers are stored in the app-support folder
(`%APPDATA%\Illuminati\Illuminati\library` on Windows).

## Logo and icons

The logo is drawn in code by `tool/make_icon.py` (Python + Pillow) into
`assets/icon/`. To change it, edit the script and run:

```sh
python tool/make_icon.py
dart run flutter_launcher_icons   # Android, Windows, macOS icons
```

Linux uses `assets/icon/app_icon.png` as the window icon.

## Copyright note

Project Gutenberg books are in the public domain **in the United States**.
Copyright terms differ by country (e.g. life + 70 years in the EU), so a book
that is free in the US may still be protected elsewhere. The app shows this
notice on every book page and in About.

## Before publishing

- Put a contact URL (website or public repository) in `CatalogService.userAgent`
  (`lib/services/catalog_service.dart`). Wikimedia asks apps to identify
  themselves this way and rate-limits anonymous clients more strictly.

- Android: create a signing key and configure `android/app/build.gradle.kts`
  (release builds currently use the debug key).
- Change the application id `com.illuminati.illuminati` if you own a domain.
