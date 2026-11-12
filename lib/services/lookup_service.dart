import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'catalog_service.dart';

class DictionaryEntry {
  final String language; // e.g. "Spanish"
  final String languageCode; // e.g. "es"
  final String partOfSpeech;
  final List<String> definitions;
  const DictionaryEntry(this.language, this.languageCode, this.partOfSpeech, this.definitions);
}

class Translation {
  final String text;
  final String? detectedLanguage;
  const Translation(this.text, this.detectedLanguage);
}

class LookupException implements Exception {
  final String message;
  LookupException(this.message);
  @override
  String toString() => message;
}

/// Online word lookup and translation.
/// - Definitions: Wiktionary (en.wiktionary.org REST API), which covers words
///   in many languages, with glosses written in English.
/// - Translation: MyMemory (api.mymemory.translated.net), free without a key
///   for light use.
class LookupService {
  final http.Client _client;
  LookupService([http.Client? client]) : _client = client ?? http.Client();

  final _defCache = <String, List<DictionaryEntry>>{};

  /// Definitions for [word], with entries for [preferLanguage] first.
  Future<List<DictionaryEntry>> define(String word, {String? preferLanguage}) async {
    final clean = cleanWord(word);
    if (clean.isEmpty) return const [];
    final key = '$clean|$preferLanguage';
    final cached = _defCache[key];
    if (cached != null) return cached;

    // Try the word as written, then lowercase (sentence-initial capitals).
    final candidates = {clean, clean.toLowerCase()};
    List<DictionaryEntry> entries = const [];
    for (final w in candidates) {
      entries = await _fetchDefinitions(w);
      if (entries.isNotEmpty) break;
    }
    if (preferLanguage != null) {
      entries = [
        ...entries.where((e) => e.languageCode == preferLanguage),
        ...entries.where((e) => e.languageCode != preferLanguage),
      ];
    }
    return _defCache[key] = entries;
  }

  Future<List<DictionaryEntry>> _fetchDefinitions(String word) async {
    final uri = Uri.parse('https://en.wiktionary.org/api/rest_v1/page/definition/'
        '${Uri.encodeComponent(word)}?redirect=true');
    final res = await _client
        .get(uri, headers: {'User-Agent': CatalogService.userAgent})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode == 404) return const [];
    if (res.statusCode != 200) {
      throw LookupException('The dictionary is unavailable (${res.statusCode}).');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final out = <DictionaryEntry>[];
    data.forEach((code, list) {
      if (list is! List) return;
      for (final item in list) {
        if (item is! Map) continue;
        final defs = <String>[];
        for (final d in (item['definitions'] as List?) ?? const []) {
          final text = _stripHtml((d as Map)['definition'] as String? ?? '');
          if (text.isNotEmpty) defs.add(text);
        }
        if (defs.isEmpty) continue;
        out.add(DictionaryEntry(
          item['language'] as String? ?? code,
          code,
          item['partOfSpeech'] as String? ?? '',
          defs,
        ));
      }
    });
    return out;
  }

  /// Translates [text] into [to]. [from] may be null to auto-detect.
  Future<Translation> translate(String text, {String? from, required String to}) async {
    final chunks = _chunks(text.trim(), 450);
    final parts = <String>[];
    String? detected;
    for (final chunk in chunks) {
      final uri = Uri.parse('https://api.mymemory.translated.net/get').replace(
          queryParameters: {'q': chunk, 'langpair': '${from ?? 'Autodetect'}|$to'});
      final res = await _client
          .get(uri, headers: {'User-Agent': CatalogService.userAgent})
          .timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) {
        throw LookupException('Translation is unavailable (${res.statusCode}).');
      }
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (j['quotaFinished'] == true) {
        throw LookupException('The free daily translation limit has been reached.');
      }
      // Errors come back with HTTP 200 and the message in responseDetails.
      final status = int.tryParse('${j['responseStatus']}') ?? 200;
      if (status != 200) {
        final details = '${j['responseDetails'] ?? ''}'.trim();
        throw LookupException(details.isEmpty
            ? 'Translation failed ($status).'
            : details[0] + details.substring(1).toLowerCase());
      }
      final rd = (j['responseData'] as Map?)?.cast<String, dynamic>() ?? {};
      var out = rd['translatedText'] as String? ?? '';
      detected ??= rd['detectedLanguage'] as String?;
      // A fuzzy translation-memory hit may drop words; prefer machine
      // translation unless the memory match is exact.
      final match = (rd['match'] as num?)?.toDouble() ?? 0;
      if (match < 0.99) {
        final matches = j['matches'];
        for (final m in matches is List ? matches : const []) {
          if (m is Map && m['created-by'] == 'MT!' && m['translation'] is String) {
            out = m['translation'] as String;
            break;
          }
        }
      }
      if (out.toUpperCase().startsWith('MYMEMORY WARNING')) {
        throw LookupException('The free daily translation limit has been reached.');
      }
      parts.add(out);
    }
    return Translation(parts.join(' '), detected);
  }

  /// Strips surrounding punctuation: "“Hello,”" -> "Hello".
  static String cleanWord(String s) => s
      .trim()
      .replaceAll(RegExp(r"^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$", unicode: true), '');

  static String _stripHtml(String html) => (html_parser.parseFragment(html).text ?? '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Splits long text at sentence boundaries into pieces of at most [max] chars.
  static List<String> _chunks(String text, int max) {
    if (text.length <= max) return [text];
    final sentences = text.split(RegExp(r'(?<=[.!?;:])\s+'));
    final out = <String>[];
    var cur = StringBuffer();
    for (final s in sentences) {
      if (cur.length + s.length + 1 > max && cur.isNotEmpty) {
        out.add(cur.toString());
        cur = StringBuffer();
      }
      if (s.length > max) {
        for (var i = 0; i < s.length; i += max) {
          out.add(s.substring(i, i + max > s.length ? s.length : i + max));
        }
      } else {
        if (cur.isNotEmpty) cur.write(' ');
        cur.write(s);
      }
    }
    if (cur.isNotEmpty) out.add(cur.toString());
    return out;
  }
}
