import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/catalog_service.dart';
import 'services/library_service.dart';
import 'services/lookup_service.dart';
import 'services/settings_service.dart';
import 'services/title_index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  final catalog = CatalogService();
  final library = LibraryService(catalog);
  await Future.wait([settings.init(), library.init()]);
  // Download/refresh the offline title index in the background.
  final titleIndex = TitleIndex()..load();
  runApp(IlluminatiApp(
    services: AppServices(
      catalog: catalog,
      titleIndex: titleIndex,
      lookup: LookupService(),
      library: library,
      settings: settings,
    ),
  ));
}

class AppServices {
  final CatalogService catalog;
  final TitleIndex titleIndex;
  final LookupService lookup;
  final LibraryService library;
  final SettingsService settings;
  const AppServices({
    required this.catalog,
    required this.titleIndex,
    required this.lookup,
    required this.library,
    required this.settings,
  });
}

/// Makes [AppServices] available to every screen via `Services.of(context)`.
class Services extends InheritedWidget {
  final AppServices services;
  const Services({super.key, required this.services, required super.child});

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Services>()!.services;

  @override
  bool updateShouldNotify(Services oldWidget) => services != oldWidget.services;
}

class IlluminatiApp extends StatelessWidget {
  final AppServices services;
  const IlluminatiApp({super.key, required this.services});

  static const seed = Color(0xFF6B4EA0); // deep violet

  ThemeData _theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: b,
      tertiary: const Color(0xFFC9A227), // gold accent
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Services(
      services: services,
      child: MaterialApp(
        title: 'Illuminati',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }
}
