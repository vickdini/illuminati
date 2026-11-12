// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class L10nEs extends L10n {
  L10nEs([String locale = 'es']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Quitar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get done => 'Listo';

  @override
  String get create => 'Crear';

  @override
  String get rename => 'Renombrar';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get back => 'Volver';

  @override
  String get undo => 'Deshacer';

  @override
  String get close => 'Cerrar';

  @override
  String get unknownAuthor => 'Autor desconocido';

  @override
  String get about => 'Acerca de';

  @override
  String get displayAccessibility => 'Pantalla y accesibilidad';

  @override
  String get aboutText =>
      'Illuminati te permite buscar, descargar y leer libros que nunca tuvieron derechos de autor o cuyos derechos ya expiraron.\n\nLos libros provienen de Project Gutenberg (gutenberg.org), Standard Ebooks (standardebooks.org), Wikisource (wikisource.org, en EPUB generados por WS Export) e Internet Archive (archive.org). Son de dominio público en Estados Unidos, salvo algunos textos de Wikisource que tienen licencias libres. Las leyes de derechos de autor varían según el país, así que consulta las de tu país antes de descargar.\n\nLas definiciones provienen de Wiktionary y las traducciones de MyMemory; el texto seleccionado se envía a esos servicios.';

  @override
  String get discoverFreeBooks => 'Descubre libros gratis';

  @override
  String get discoverSubtitle =>
      'Clásicos cuyos derechos de autor expiraron, gratis para descargar y conservar.';

  @override
  String get searchHint => 'Buscar por título o autor';

  @override
  String get catalogLanguage => 'Idioma del catálogo';

  @override
  String get allLanguages => 'Todos los idiomas';

  @override
  String get gutenbergSubtitle =>
      'La mayor biblioteca gratuita: más de 75.000 libros de dominio público';

  @override
  String get noBooksFound => 'No se encontraron libros. Prueba otra búsqueda.';

  @override
  String get catalogTimeout =>
      'El catálogo está tardando demasiado en responder.';

  @override
  String get catalogOffline =>
      'No se pudo cargar el catálogo. Revisa tu conexión a internet.';

  @override
  String couldNotReach(String source) {
    return 'No se pudo conectar con $source.';
  }

  @override
  String get downloadFree => 'Descargar gratis';

  @override
  String get yourLibrary => 'Tu biblioteca';

  @override
  String libraryAndShelves(int count) {
    return 'Biblioteca y estantes ($count)';
  }

  @override
  String get libraryEmptyHome =>
      'Tu biblioteca está vacía. Los libros que descargues del catálogo aparecerán aquí, listos para leer sin conexión.';

  @override
  String noDownloadedSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No hay libros descargados. Tus $count libros guardados están en Biblioteca y estantes.',
      one:
          'No hay libros descargados. Tu libro guardado está en Biblioteca y estantes.',
    );
    return '$_temp0';
  }

  @override
  String get catPopular => 'Populares';

  @override
  String get catFiction => 'Ficción';

  @override
  String get catMystery => 'Misterio';

  @override
  String get catAdventure => 'Aventura';

  @override
  String get catScienceFiction => 'Ciencia ficción';

  @override
  String get catRomance => 'Romance';

  @override
  String get catHorror => 'Terror';

  @override
  String get catFantasy => 'Fantasía';

  @override
  String get catChildren => 'Infantil';

  @override
  String get catPoetry => 'Poesía';

  @override
  String get catDrama => 'Teatro';

  @override
  String get catPhilosophy => 'Filosofía';

  @override
  String get catHistory => 'Historia';

  @override
  String get catScience => 'Ciencia';

  @override
  String get catBiography => 'Biografía';

  @override
  String get taglineStandardEbooks =>
      'Clásicos con una tipografía cuidada y revisados con esmero';

  @override
  String get taglineWikisource =>
      'Textos transcritos por voluntarios en muchos idiomas';

  @override
  String get taglineArchive =>
      'Escaneos de ediciones impresas antiguas (texto obtenido por OCR)';

  @override
  String rightsGutenberg(int id) {
    return 'De Project Gutenberg (libro electrónico n.º $id). Este libro es de dominio público en Estados Unidos. Las leyes de derechos de autor varían según el país, así que consulta las de tu país antes de descargar.';
  }

  @override
  String get rightsStandardEbooks =>
      'De Standard Ebooks, cuyas ediciones son de dominio público en Estados Unidos y ceden al dominio público (CC0) sus propios cambios. Las leyes de derechos de autor varían según el país, así que consulta las de tu país.';

  @override
  String get rightsWikisource =>
      'De Wikisource, transcrito por voluntarios; el EPUB lo genera WS Export. Wikisource aloja textos de dominio público y algunos con licencias libres (como CC BY-SA), que permiten leerlos y compartirlos libremente. Consulta las leyes de tu país.';

  @override
  String rightsArchive(String year) {
    return 'De Internet Archive. Solo se muestran libros publicados en $year o antes, por lo que son de dominio público en Estados Unidos. El texto del EPUB se generó automáticamente a partir de escaneos y puede contener errores. Las leyes de derechos de autor varían según el país, así que consulta las de tu país.';
  }

  @override
  String addedToLibrary(String title) {
    return '«$title» se añadió a tu biblioteca';
  }

  @override
  String couldNotDownload(String title, String error) {
    return 'No se pudo descargar «$title»: $error';
  }

  @override
  String get removeFromLibraryQuestion => '¿Quitar de la biblioteca?';

  @override
  String removeFromLibraryBody(String title) {
    return '«$title» se quitará de tu biblioteca y de tus estantes, junto con sus notas, subrayados y marcadores. Puedes volver a descargarlo cuando quieras.';
  }

  @override
  String get continueReading => 'Seguir leyendo';

  @override
  String get readNow => 'Leer ahora';

  @override
  String get downloading => 'Descargando…';

  @override
  String downloadingPercent(int percent) {
    return 'Descargando $percent %';
  }

  @override
  String get noEbookEdition => 'Sin edición electrónica';

  @override
  String get freeToRead => 'Lectura libre';

  @override
  String get publicDomain => 'Dominio público';

  @override
  String downloadsCount(String count) {
    return '$count descargas';
  }

  @override
  String get getIllustratedEdition => 'Obtener la edición ilustrada';

  @override
  String get illustratedDownloaded => 'Edición ilustrada descargada';

  @override
  String get removeDownload => 'Quitar la descarga';

  @override
  String get removeFromLibrary => 'Quitar de la biblioteca';

  @override
  String get aboutThisBook => 'Sobre este libro';

  @override
  String get subjects => 'Temas';

  @override
  String get wantToRead => 'Quiero leerlo';

  @override
  String get finished => 'Terminado';

  @override
  String get addToShelf => 'Añadir a un estante';

  @override
  String onShelf(String name) {
    return 'En «$name»';
  }

  @override
  String onShelves(int count) {
    return 'En $count estantes';
  }

  @override
  String get newShelf => 'Nuevo estante';

  @override
  String get newShelfEllipsis => 'Nuevo estante…';

  @override
  String get shelfNameHint => 'p. ej. Favoritos, Filosofía, Pendientes';

  @override
  String get renameShelf => 'Renombrar estante';

  @override
  String get deleteShelf => 'Eliminar estante';

  @override
  String deleteShelfQuestion(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get deleteShelfBody =>
      'Se elimina el estante; sus libros siguen en tu biblioteca.';

  @override
  String get noShelvesYet =>
      'Todavía no tienes estantes. Crea uno para agrupar tus libros como quieras.';

  @override
  String bookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String get bookDetails => 'Detalles del libro';

  @override
  String get addToShelfEllipsis => 'Añadir a un estante…';

  @override
  String get removeFromWantToRead => 'Quitar de «Quiero leerlo»';

  @override
  String get markNotFinished => 'Marcar como no terminado';

  @override
  String get markFinished => 'Marcar como terminado';

  @override
  String downloadRemoved(String title) {
    return 'Descarga eliminada. «$title» sigue en tu biblioteca con tus notas y tu posición.';
  }

  @override
  String get sort => 'Ordenar';

  @override
  String get filterHint => 'Filtrar por título o autor';

  @override
  String get viewAll => 'Todos';

  @override
  String get viewDownloaded => 'Descargados';

  @override
  String get viewReading => 'Leyendo';

  @override
  String get shelfHint =>
      'Haz clic derecho o mantén pulsado un estante para renombrarlo o eliminarlo. Añade libros con «Añadir a un estante» en cualquier libro.';

  @override
  String noBooksMatch(String query) {
    return 'Ningún libro coincide con «$query».';
  }

  @override
  String get emptyShelf =>
      'Este estante está vacío.\nAbre cualquier libro y elige «Añadir a un estante».';

  @override
  String get emptyDownloaded => 'No hay libros descargados.';

  @override
  String get emptyWantToRead =>
      'Todavía no hay nada aquí.\nMarca libros del catálogo como «Quiero leerlo»; se guardan sin descargarlos.';

  @override
  String get emptyReading => 'No estás leyendo ningún libro ahora mismo.';

  @override
  String get emptyFinished => 'Aquí aparecen los libros que terminas.';

  @override
  String get emptyLibrary => 'Tu biblioteca está vacía.';

  @override
  String get sortRecent => 'Leídos recientemente';

  @override
  String get sortTitle => 'Título';

  @override
  String get sortAuthor => 'Autor';

  @override
  String get sortProgress => 'Progreso';

  @override
  String get sortAdded => 'Añadidos recientemente';

  @override
  String get tileNew => 'Nuevo';

  @override
  String get notDownloaded => 'Sin descargar';

  @override
  String get note => 'Nota';

  @override
  String get writeNote => 'Escribe una nota…';

  @override
  String get removeHighlight => 'Quitar subrayado';

  @override
  String get contents => 'Índice';

  @override
  String bookmarksCount(int count) {
    return 'Marcadores ($count)';
  }

  @override
  String notesCount(int count) {
    return 'Notas ($count)';
  }

  @override
  String get unknownChapter => 'Capítulo desconocido';

  @override
  String get noBookmarks =>
      'Todavía no hay marcadores.\nUsa el botón de marcador de la barra de herramientas (o Ctrl+B).';

  @override
  String get bookmark => 'Marcador';

  @override
  String get deleteBookmark => 'Eliminar marcador';

  @override
  String get noHighlights =>
      'Todavía no hay subrayados.\nSelecciona texto y elige Subrayar o Nota. En una computadora, haz clic derecho sobre la selección.';

  @override
  String get copyAllMarkdown => 'Copiar todo en Markdown';

  @override
  String get notesCopied => 'Notas copiadas al portapapeles';

  @override
  String get editNote => 'Editar nota';

  @override
  String get addNote => 'Añadir nota';

  @override
  String get editHighlight => 'Editar subrayado';

  @override
  String get highlight => 'Subrayar';

  @override
  String get define => 'Definir';

  @override
  String get translate => 'Traducir';

  @override
  String get closeImage => 'Cerrar imagen';

  @override
  String bookOpenError(String error) {
    return 'No se pudo abrir este libro.\n$error';
  }

  @override
  String get lessThanMinuteLeft => 'Queda menos de un minuto del capítulo';

  @override
  String minutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Quedan $minutes min del capítulo',
      one: 'Queda 1 min del capítulo',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutesLeft(int hours, int minutes) {
    return 'Quedan $hours h $minutes min del capítulo';
  }

  @override
  String finishedBook(String title) {
    return 'Terminaste «$title». Ya está en tu lista de terminados.';
  }

  @override
  String get search => 'Buscar';

  @override
  String searchNoMatches(String query) {
    return '«$query» · sin resultados';
  }

  @override
  String searchPosition(String query, int index, int total) {
    return '«$query» · $index de $total';
  }

  @override
  String get previousMatch => 'Resultado anterior';

  @override
  String get nextMatch => 'Resultado siguiente (F3)';

  @override
  String get closeSearch => 'Cerrar búsqueda';

  @override
  String get theEnd => '— Fin —';

  @override
  String nextChapterTitle(String title) {
    return 'Siguiente: $title';
  }

  @override
  String get backToLibrary => 'Volver a la biblioteca';

  @override
  String get searchInBookShortcut => 'Buscar en el libro (Ctrl+F)';

  @override
  String get removeBookmarkShortcut => 'Quitar marcador (Ctrl+B)';

  @override
  String get bookmarkPageShortcut => 'Marcar esta página (Ctrl+B)';

  @override
  String get contentsBookmarksNotes => 'Índice, marcadores y notas';

  @override
  String get displaySettings => 'Ajustes de pantalla';

  @override
  String get previousChapter => 'Capítulo anterior';

  @override
  String get nextChapter => 'Capítulo siguiente';

  @override
  String chapterStatus(String title, int index, int total, int percent) {
    return '$title  ·  Capítulo $index de $total  ·  $percent % leído';
  }

  @override
  String get searchInThisBook => 'Buscar en este libro';

  @override
  String get typeTwoLetters => 'Escribe al menos dos letras.';

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Sin resultados',
    );
    return '$_temp0';
  }

  @override
  String matchesMany(int count) {
    return 'Más de $count resultados';
  }

  @override
  String get translation => 'Traducción';

  @override
  String get noDefinition => 'No se encontró ninguna definición.';

  @override
  String get translateInstead => 'Traducir en su lugar';

  @override
  String get definitionsCredit =>
      'Definiciones de Wiktionary (CC BY-SA), en inglés.';

  @override
  String get translateInto => 'Al:';

  @override
  String get alreadyInLanguage =>
      'Este libro ya está en ese idioma. Elige otro arriba.';

  @override
  String get translationCredit =>
      'Traducciones de MyMemory. El texto seleccionado se envía a su servicio.';

  @override
  String get langAr => 'Árabe';

  @override
  String get langZh => 'Chino';

  @override
  String get langNl => 'Neerlandés';

  @override
  String get langEn => 'Inglés';

  @override
  String get langFr => 'Francés';

  @override
  String get langDe => 'Alemán';

  @override
  String get langEl => 'Griego';

  @override
  String get langHe => 'Hebreo';

  @override
  String get langHi => 'Hindi';

  @override
  String get langIt => 'Italiano';

  @override
  String get langJa => 'Japonés';

  @override
  String get langKo => 'Coreano';

  @override
  String get langPl => 'Polaco';

  @override
  String get langPt => 'Portugués';

  @override
  String get langRu => 'Ruso';

  @override
  String get langEs => 'Español';

  @override
  String get langSv => 'Sueco';

  @override
  String get langTr => 'Turco';

  @override
  String get appLanguage => 'Idioma de la aplicación';

  @override
  String get sameAsDevice => 'Igual que el dispositivo';

  @override
  String get previewText =>
      'Era el mejor de los tiempos, era el peor de los tiempos; la edad de la sabiduría, y también de la locura.';

  @override
  String get sectionText => 'Texto';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get fontDescSerif =>
      'Literata: una tipografía con serifas diseñada para leer en pantalla.';

  @override
  String get fontDescGaramond =>
      'EB Garamond: un tipo de libro clásico, basado en tipos del siglo XVI.';

  @override
  String get fontDescSans =>
      'Atkinson Hyperlegible: una tipografía sin serifas creada por el Braille Institute para que las letras parecidas se distingan con facilidad.';

  @override
  String get fontDescDyslexic =>
      'OpenDyslexic tiene la base de las letras más gruesa para ayudar a que no se inviertan ni se intercambien. A muchos lectores también les resulta más fácil con más espacio entre letras y sin texto justificado.';

  @override
  String get textSize => 'Tamaño del texto';

  @override
  String get lineSpacing => 'Interlineado';

  @override
  String get letterSpacing => 'Espaciado entre letras';

  @override
  String get normal => 'Normal';

  @override
  String get justifyText => 'Justificar el texto';

  @override
  String get justifySubtitle =>
      'Borde derecho uniforme. Desactívalo para que los espacios entre palabras sean iguales.';

  @override
  String get sectionPage => 'Página';

  @override
  String get margins => 'Márgenes';

  @override
  String get lineWidth => 'Ancho de línea';

  @override
  String get lineWidthHint =>
      'Las líneas más cortas se siguen con más facilidad; la columna de texto nunca es más ancha que la pantalla menos los márgenes.';

  @override
  String get sectionScreen => 'Pantalla';

  @override
  String get brightness => 'Brillo';

  @override
  String get warmth => 'Calidez';

  @override
  String get off => 'Desactivado';

  @override
  String get screenHint =>
      'El brillo y la calidez se aplican a toda la aplicación, además de los ajustes de tu dispositivo. La calidez reduce la luz azul, como un modo nocturno.';

  @override
  String readingSpeed(int wpm) {
    return 'Velocidad de lectura: unas $wpm palabras por minuto (se ajusta mientras lees).';
  }

  @override
  String get resetDefaults => 'Restablecer valores predeterminados';

  @override
  String errCatalogHttp(int status) {
    return 'El catálogo devolvió un error ($status).';
  }

  @override
  String get errSearchFailed => 'La búsqueda falló.';

  @override
  String get errNoOtherEdition => 'No hay otra edición de este libro.';

  @override
  String get errNoEpub =>
      'Este título no tiene edición electrónica (puede ser un audiolibro).';

  @override
  String get errDownloadTimeout =>
      'La descarga tardó demasiado. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String errDownloadHttp(int status) {
    return 'La descarga falló ($status).';
  }

  @override
  String get errInvalidEpub => 'El archivo descargado no es un EPUB válido.';

  @override
  String get errWikisourceTooLong =>
      'Wikisource no pudo preparar este libro: es demasiado largo para su servicio de EPUB. Prueba con uno de sus volúmenes o búscalo en otro catálogo.';

  @override
  String errDictionary(int status) {
    return 'El diccionario no está disponible ($status).';
  }

  @override
  String errTranslationUnavailable(int status) {
    return 'La traducción no está disponible ($status).';
  }

  @override
  String get errTranslationQuota =>
      'Se alcanzó el límite diario de traducciones gratuitas.';

  @override
  String errTranslationFailed(int status) {
    return 'La traducción falló ($status).';
  }

  @override
  String errSourceBusy(String host) {
    return '$host está ocupado; inténtalo de nuevo en un minuto.';
  }

  @override
  String errSourceHttp(String host, int status) {
    return '$host devolvió un error ($status).';
  }

  @override
  String get errTimeout =>
      'La conexión tardó demasiado. Revisa tu conexión a internet e inténtalo de nuevo.';

  @override
  String get errGeneric => 'Algo salió mal. Inténtalo de nuevo.';
}
