import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';

/// A book cover: the local file if downloaded, otherwise the catalog image,
/// otherwise a generated placeholder showing the title.
class BookCover extends StatelessWidget {
  final Book book;
  final String? localPath;
  final double? width;
  final double? height;

  const BookCover(
      {super.key, required this.book, this.localPath, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (localPath != null && File(localPath!).existsSync()) {
      image = Image.file(File(localPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Placeholder(book: book));
    } else if (book.coverUrl != null) {
      image = Image.network(
        book.coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Placeholder(book: book),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      );
    } else {
      image = _Placeholder(book: book);
    }

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: image,
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Book book;
  const _Placeholder({required this.book});

  static const _palettes = [
    [Color(0xFF3E2C6B), Color(0xFF6B4EA0)],
    [Color(0xFF1F4E5F), Color(0xFF3B8EA5)],
    [Color(0xFF5F2A2A), Color(0xFFA54B3B)],
    [Color(0xFF2E4A2B), Color(0xFF5E8C4E)],
    [Color(0xFF4A3B1F), Color(0xFFB08D3C)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[book.id % _palettes.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'serif'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.authorLine,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
