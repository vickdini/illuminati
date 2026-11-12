import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:illuminati/models/book.dart';
import 'package:illuminati/models/shelf.dart';
import 'package:illuminati/services/catalog_service.dart';
import 'package:illuminati/services/library_service.dart';
import 'package:illuminati/sources/book_source.dart';

Book _book(int id, String title, String author) =>
    Book(id: id, title: title, authors: [author]);

Map<String, dynamic> _entry(Book b, {String? epub, double progress = 0, String? opened}) => {
      'book': b.toJson(),
      'epubPath': epub,
      'addedAt': '2026-01-0${b.id % 9 + 1}T00:00:00.000',
      'lastOpened': opened,
      'progress': progress,
    };

void main() {
  late Directory dir;
  late File epub;
  final created = <LibraryService>[];
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lib');
    epub = File('${dir.path}/1.epub')..writeAsStringSync('PK');
  });
  tearDown(() async {
    for (final lib in created) {
      await lib.saved;
    }
    created.clear();
    await dir.delete(recursive: true);
  });

  LibraryService service() {
    final lib = LibraryService(SourceRegistry(CatalogService(), []))..useDirectory(dir);
    created.add(lib);
    return lib;
  }

  test('reads the old list format; a missing file means "not downloaded"', () {
    final lib = service()
      ..load([
        _entry(_book(1, 'Emma', 'Jane Austen'), epub: epub.path),
        _entry(_book(2, 'Dracula', 'Bram Stoker'), epub: '${dir.path}/gone.epub'),
      ]);
    expect(lib.entries.length, 2, reason: 'nothing is dropped any more');
    expect(lib.isDownloaded(1), isTrue);
    expect(lib.isDownloaded(2), isFalse);
    expect(lib.has(2), isTrue);
    expect(lib.downloaded.map((e) => e.book.id), [1]);
  });

  test('views, statuses, filter and sorting', () {
    final lib = service()
      ..load({
        'version': 2,
        'entries': [
          _entry(_book(1, 'The Time Machine', 'H. G. Wells'), epub: epub.path, progress: 0.4,
              opened: '2026-03-01T00:00:00.000'),
          _entry(_book(2, 'Dracula', 'Bram Stoker'), epub: epub.path, progress: 0.9,
              opened: '2026-02-01T00:00:00.000'),
          _entry(_book(3, 'Émile', 'Jean-Jacques Rousseau')),
        ],
      });
    lib.setStatus(_book(2, 'Dracula', 'Bram Stoker'), ReadingStatus.finished);
    lib.setStatus(_book(3, 'Émile', 'Jean-Jacques Rousseau'), ReadingStatus.wantToRead);
    // A catalog book saved before downloading.
    lib.setStatus(_book(4, 'Anna Karenina', 'Leo Tolstoy'), ReadingStatus.wantToRead);

    ids(String view, {LibrarySort sort = LibrarySort.title, String filter = ''}) =>
        lib.entriesIn(view, sort: sort, filter: filter).map((e) => e.book.id).toList();

    expect(ids(LibraryView.wantToRead), [4, 3]);
    expect(ids(LibraryView.finished), [2]);
    expect(ids(LibraryView.reading), [1], reason: 'finished books are not "reading"');
    expect(ids(LibraryView.downloaded), [2, 1]);
    expect(ids(LibraryView.all), [4, 2, 3, 1],
        reason: 'by title, ignoring accents and "The": Anna, Dracula, Émile, Time');
    expect(ids(LibraryView.all, sort: LibrarySort.author), [3, 2, 4, 1],
        reason: 'by surname: Rousseau, Stoker, Tolstoy, Wells');
    expect(ids(LibraryView.all, sort: LibrarySort.progress).take(2), [2, 1]);
    expect(ids(LibraryView.all, sort: LibrarySort.recent).take(2), [4, 1],
        reason: 'just added, then most recently opened');
    expect(ids(LibraryView.all, filter: 'emile'), [3]);
    expect(ids(LibraryView.all, filter: 'stoker drac'), [2]);

    lib.markOpened(3);
    expect(lib.entry(3)!.status, ReadingStatus.none, reason: 'opening ends "want to read"');
  });

  test('shelves: add (saving the book), rename, round trip, delete', () {
    final lib = service();
    final fav = lib.createShelf(' Favorites ');
    final phil = lib.createShelf('Philosophy');
    final book = _book(7, 'Meditations', 'Marcus Aurelius');
    lib.setOnShelf(phil, book, true);
    lib.setOnShelf(fav, book, true);
    lib.setOnShelf(fav, book, true); // no duplicates
    expect(lib.has(7), isTrue, reason: 'a shelf can hold a book before it is downloaded');
    expect(fav.name, 'Favorites');
    expect(fav.bookIds, [7]);
    expect(lib.shelvesOf(7).map((s) => s.name), ['Favorites', 'Philosophy']);
    expect(lib.entriesIn(LibraryView.shelf(phil.id)).single.book.title, 'Meditations');

    lib.renameShelf(phil, 'Stoics');
    final copy = service()..load(jsonDecode(jsonEncode(lib.toJson())));
    expect(copy.shelves.map((s) => '${s.name}: ${s.bookIds}'), ['Favorites: [7]', 'Stoics: [7]']);

    lib.setOnShelf(fav, book, false);
    lib.deleteShelf(phil);
    expect(lib.shelves.single.bookIds, isEmpty);
    expect(lib.has(7), isTrue, reason: 'deleting a shelf keeps its books');
  });

  test('remove download keeps the book; remove from library takes it off shelves', () async {
    final lib = service()..load([_entry(_book(1, 'Emma', 'Jane Austen'), epub: epub.path)]);
    final shelf = lib.createShelf('Austen');
    lib.setOnShelf(shelf, lib.entry(1)!.book, true);

    await lib.removeDownload(1);
    expect(epub.existsSync(), isFalse);
    expect(lib.has(1), isTrue);
    expect(lib.isDownloaded(1), isFalse);
    expect(shelf.bookIds, [1]);

    await lib.remove(1);
    expect(lib.has(1), isFalse);
    expect(shelf.bookIds, isEmpty);

    // Everything above was saved to library.json.
    final saved = jsonDecode(File('${dir.path}/library.json').readAsStringSync()) as Map;
    expect(saved['version'], 2);
    expect(saved['entries'], isEmpty);
    expect((saved['shelves'] as List).single['name'], 'Austen');
  });
}
