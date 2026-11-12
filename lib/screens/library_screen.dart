import 'package:flutter/material.dart';

import '../main.dart';
import 'home_screen.dart';

/// Every downloaded book in a grid.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = Services.of(context).library;
    return Scaffold(
      appBar: AppBar(title: const Text('Your library')),
      body: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          final entries = library.entries;
          if (entries.isEmpty) {
            return const Center(child: Text('No downloaded books yet.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 20,
              crossAxisSpacing: 16,
              childAspectRatio: 0.5,
            ),
            itemCount: entries.length,
            itemBuilder: (context, i) =>
                LibraryTile(entry: entries[i], width: double.infinity),
          );
        },
      ),
    );
  }
}
