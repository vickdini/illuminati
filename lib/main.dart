import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/l10n_helpers.dart';
import 'screens/home_screen.dart';
import 'services/catalog_service.dart';
import 'services/library_service.dart';
import 'services/lookup_service.dart';
import 'services/settings_service.dart';
import 'services/title_index.dart';
import 'sources/book_source.dart';
import 'sources/internet_archive.dart';
import 'sources/standard_ebooks.dart';
import 'sources/wikisource.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bundled fonts' licences, shown under About -> View licenses.
  LicenseRegistry.addLicense(() async* {
    for (final (name, folder) in const [
      ('Literata', 'literata'),
      ('EB Garamond', 'ebgaramond'),
      ('Atkinson Hyperlegible', 'atkinson'),
      ('OpenDyslexic', 'opendyslexic'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString('assets/fonts/$folder/OFL.txt'));
    }
  });
  final settings = SettingsService();
  final catalog = CatalogService();
  // Extra catalogs, shown as rows above the Gutenberg grid, in this order.
  final sources = SourceRegistry(catalog, [
    StandardEbooksSource(),
    WikisourceSource(),
    InternetArchiveSource(),
  ]);
  final library = LibraryService(sources);
  await Future.wait([settings.init(), library.init()]);
  // Download/refresh the offline title index in the background.
  final titleIndex = TitleIndex()..load();
  runApp(
    IlluminatiApp(
      services: AppServices(
        catalog: catalog,
        sources: sources,
        titleIndex: titleIndex,
        lookup: LookupService(),
        library: library,
        settings: settings,
      ),
    ),
  );
}

class AppServices {
  final CatalogService catalog;
  final SourceRegistry sources;
  final TitleIndex titleIndex;
  final LookupService lookup;
  final LibraryService library;
  final SettingsService settings;
  const AppServices({
    required this.catalog,
    required this.sources,
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
      child: ValueListenableBuilder<String>(
        valueListenable: services.settings.appLanguageListenable,
        builder: (context, language, _) => MaterialApp(
          title: 'Illuminati',
          locale: language.isEmpty ? null : Locale(language),
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: L10n.localizationsDelegates,
          debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const HomeScreen(),
          // Brightness and warmth (Display & accessibility) tint everything.
          builder: (context, child) => ListenableBuilder(
            listenable: services.settings,
            builder: (context, _) => services.settings.hasScreenFilter
                ? ColorFiltered(
                    colorFilter: ColorFilter.matrix(
                      services.settings.screenFilter,
                    ),
                    child: child,
                  )
                : child!,
          ),
        ),
      ),
    );
  }
}
