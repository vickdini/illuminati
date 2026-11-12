import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../services/catalog_service.dart';

/// A free-book catalog shown as an extra row on the home screen.
/// (Project Gutenberg, the main catalog, is [CatalogService].)
abstract class BookSource {
  /// Stored in [Book.source].
  String get id;
  String get name;

  /// Whether this source has anything for the catalog language ('' = all)
  /// and category subject ('' = none). Rows are hidden otherwise.
  bool supports({required String language, required String subject});

  /// The row's default contents (popular or recommended books).
  Future<List<Book>> featured({
    required String language,
    required String subject,
  });

  Future<List<Book>> search(
    String query, {
    required String language,
    required String subject,
  });

  /// Fills in summary, subjects and the exact EPUB link.
  Future<Book> details(Book book);
}

class SourceException extends AppException {
  const SourceException(super.code, {super.status, super.host, super.detail});

  /// True when the service asked us to slow down (HTTP 429).
  bool get busy => code == ErrorCode.sourceBusy;
}

/// Shared HTTP GET with the app's User-Agent and a timeout.
Future<http.Response> sourceGet(
  http.Client client,
  Uri uri, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final res = await client
      .get(uri, headers: {'User-Agent': CatalogService.userAgent})
      .timeout(timeout);
  if (res.statusCode == 429) {
    throw SourceException(ErrorCode.sourceBusy, host: uri.host);
  }
  if (res.statusCode != 200) {
    throw SourceException(
      ErrorCode.sourceHttp,
      host: uri.host,
      status: res.statusCode,
    );
  }
  return res;
}

/// All catalogs: Gutenberg (main) plus the extra sources, in row order.
class SourceRegistry {
  final CatalogService gutenberg;
  final List<BookSource> extra;
  SourceRegistry(this.gutenberg, this.extra);

  BookSource? byId(String id) => extra.where((s) => s.id == id).firstOrNull;

  String nameOf(Book book) => book.source == 'gutenberg'
      ? 'Project Gutenberg'
      : (byId(book.source)?.name ?? book.source);

  Future<Book> details(Book book) {
    if (book.source == 'gutenberg') return gutenberg.details(book);
    final source = byId(book.source);
    if (source == null) return Future.value(book);
    return source.details(book);
  }
}

/// Keeps each source's default row for a while, so opening the app or
/// pulling to refresh doesn't hit small, volunteer-run sites every time.
/// Failures are not cached.
class FeaturedCache {
  final Duration ttl;
  FeaturedCache([this.ttl = const Duration(hours: 12)]);

  final _entries = <String, (DateTime, List<Book>)>{};

  Future<List<Book>> get(String key, Future<List<Book>> Function() load) async {
    final hit = _entries[key];
    if (hit != null && DateTime.now().difference(hit.$1) < ttl) return hit.$2;
    final books = await load();
    _entries[key] = (DateTime.now(), books);
    return books;
  }
}

/// Removes characters with special meaning in search query syntaxes.
String plainQuery(String q) => q
    .replaceAll(RegExp(r'[+\-&|!(){}\[\]^"~*?:\\/]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
