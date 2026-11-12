# Illuminati

An e-reader for Windows, macOS, Linux and Android. It works like the Kindle app,
but its whole catalog is free: books that were never under copyright or whose
copyright has expired.

- **Your library** (top): books you have downloaded, most recently read first,
  with reading progress. **Library & shelves** opens everything you've saved:
  - Views: All, Downloaded, Want to read, Reading, Finished, and your own
    **shelves** (e.g. "Favorites", "Philosophy"); a filter box; sorting by
    recently read, title, author, progress or recently added.
  - "Want to read", "Finished" and shelves work before downloading: the book is
    saved to the library; tap it to open its page and download it. Opening a book ends
    "Want to read"; reaching its end marks it Finished (with Undo).
  - Long-press or right-click any book for its menu. **Remove download** frees
    the space but keeps the book, its notes and place; **Remove from library**
    deletes everything.
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

  - **Display & accessibility** (the sliders button on the home screen, or the
    text button in the reader): four bundled reading fonts, so books look the
    same on every device: **Literata** (default), **EB Garamond**, **Atkinson
    Hyperlegible** and the dyslexia-friendly **OpenDyslexic** (all SIL Open Font
    License; see `assets/fonts/`); text size, line and
    letter spacing; justified or ragged-right text; margins and line width; and
    **brightness** and **warmth** filters that apply to the whole app.

  Keyboard: ←/→ or PageUp/PageDown turn pages, ↑/↓ scroll, Ctrl+F search,
  Ctrl+B bookmark, Esc closes search/toolbar or goes back.

## Languages

The interface is available in English, Spanish, French, German, Italian and
Portuguese. It follows the device's language, or pick one under
Display & accessibility → App language.

Texts live in `lib/l10n/app_<code>.arb` (English, `app_en.arb`, is the
template). To add a language, copy `app_en.arb` to `app_<code>.arb`, translate
the values (keep `{placeholders}` and plural forms), add the language to
`appLanguages` in `lib/l10n/l10n_helpers.dart`, and run `flutter gen-l10n` (it
also runs on every build). `flutter test` checks that every language has every
string with the same placeholders.

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
| Library: downloads, statuses, shelves, views and sorting (`library.json`) | `lib/services/library_service.dart` |
| EPUB → chapters/paragraphs (runs on a background isolate) | `lib/services/epub_parser.dart` |
| Offline title index (Gutenberg `pg_catalog.csv`, partial/accent-insensitive search) | `lib/services/title_index.dart` |
| Highlights, notes, bookmarks (`notes/<id>.json`, re-anchored by text) | `lib/models/annotation.dart` |
| Dictionary (Wiktionary) and translation (MyMemory) | `lib/services/lookup_service.dart` |
| In-book search | `lib/services/book_search.dart` |
| Reader, display and accessibility settings (`settings.json`) | `lib/services/settings_service.dart` |
| Display & accessibility panel | `lib/widgets/display_settings.dart` |
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

- Requests identify the app with the repository URL (`CatalogService.userAgent`
  in `lib/services/catalog_service.dart`), as Wikimedia asks. If the project
  moves or gets its own website, update it there.

- Android: create a signing key and configure `android/app/build.gradle.kts`
  (release builds currently use the debug key).
- Change the application id `com.illuminati.illuminati` if you own a domain.
