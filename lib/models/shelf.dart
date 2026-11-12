/// A user-made collection of books, e.g. "Favorites" or "Philosophy".
class Shelf {
  final String id;
  String name;

  /// Book ids, in the order they were added.
  final List<int> bookIds;
  final DateTime created;

  Shelf({
    required this.id,
    required this.name,
    List<int>? bookIds,
    required this.created,
  }) : bookIds = bookIds ?? [];

  bool contains(int bookId) => bookIds.contains(bookId);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'books': bookIds,
    'created': created.toIso8601String(),
  };

  factory Shelf.fromJson(Map<String, dynamic> j) => Shelf(
    id: j['id'] as String,
    name: j['name'] as String,
    bookIds: ((j['books'] as List?) ?? const []).cast<int>().toList(),
    created: DateTime.parse(j['created'] as String),
  );
}

/// How the library is sorted.
enum LibrarySort { recent, title, author, progress, added }
