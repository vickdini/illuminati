// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class L10nPt extends L10n {
  L10nPt([String locale = 'pt']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String get delete => 'Excluir';

  @override
  String get save => 'Salvar';

  @override
  String get done => 'Concluído';

  @override
  String get create => 'Criar';

  @override
  String get rename => 'Renomear';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get back => 'Voltar';

  @override
  String get undo => 'Desfazer';

  @override
  String get close => 'Fechar';

  @override
  String get unknownAuthor => 'Autor desconhecido';

  @override
  String get about => 'Sobre';

  @override
  String get displayAccessibility => 'Tela e acessibilidade';

  @override
  String get aboutText =>
      'O Illuminati permite encontrar, baixar e ler livros que nunca tiveram direitos autorais ou cujos direitos já expiraram.\n\nOs livros vêm do Project Gutenberg (gutenberg.org), Standard Ebooks (standardebooks.org), Wikisource (wikisource.org, em EPUB gerados pelo WS Export) e Internet Archive (archive.org). Eles estão em domínio público nos Estados Unidos, exceto alguns textos do Wikisource com licenças livres. As leis de direitos autorais variam de país para país, então verifique as do seu país antes de baixar.\n\nAs definições vêm do Wiktionary e as traduções do MyMemory; o texto selecionado é enviado a esses serviços.';

  @override
  String get discoverFreeBooks => 'Descubra livros grátis';

  @override
  String get discoverSubtitle =>
      'Clássicos cujos direitos autorais expiraram, grátis para baixar e guardar.';

  @override
  String get searchHint => 'Pesquisar por título ou autor';

  @override
  String get catalogLanguage => 'Idioma do catálogo';

  @override
  String get allLanguages => 'Todos os idiomas';

  @override
  String get gutenbergSubtitle =>
      'A maior biblioteca gratuita: mais de 75.000 livros em domínio público';

  @override
  String get noBooksFound => 'Nenhum livro encontrado. Tente outra pesquisa.';

  @override
  String get catalogTimeout =>
      'O catálogo está demorando demais para responder.';

  @override
  String get catalogOffline =>
      'Não foi possível carregar o catálogo. Verifique sua conexão com a internet.';

  @override
  String couldNotReach(String source) {
    return 'Não foi possível acessar $source.';
  }

  @override
  String get downloadFree => 'Baixar grátis';

  @override
  String get yourLibrary => 'Sua biblioteca';

  @override
  String libraryAndShelves(int count) {
    return 'Biblioteca e estantes ($count)';
  }

  @override
  String get libraryEmptyHome =>
      'Sua biblioteca está vazia. Os livros que você baixar do catálogo aparecerão aqui, prontos para ler offline.';

  @override
  String noDownloadedSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nenhum livro baixado. Seus $count livros salvos estão em Biblioteca e estantes.',
      one:
          'Nenhum livro baixado. Seu livro salvo está em Biblioteca e estantes.',
    );
    return '$_temp0';
  }

  @override
  String get catPopular => 'Populares';

  @override
  String get catFiction => 'Ficção';

  @override
  String get catMystery => 'Mistério';

  @override
  String get catAdventure => 'Aventura';

  @override
  String get catScienceFiction => 'Ficção científica';

  @override
  String get catRomance => 'Romance';

  @override
  String get catHorror => 'Terror';

  @override
  String get catFantasy => 'Fantasia';

  @override
  String get catChildren => 'Infantil';

  @override
  String get catPoetry => 'Poesia';

  @override
  String get catDrama => 'Teatro';

  @override
  String get catPhilosophy => 'Filosofia';

  @override
  String get catHistory => 'História';

  @override
  String get catScience => 'Ciência';

  @override
  String get catBiography => 'Biografia';

  @override
  String get taglineStandardEbooks =>
      'Clássicos com tipografia cuidadosa e revisão atenta';

  @override
  String get taglineWikisource =>
      'Textos transcritos por voluntários em muitos idiomas';

  @override
  String get taglineArchive =>
      'Digitalizações de edições impressas antigas (texto obtido por OCR)';

  @override
  String rightsGutenberg(int id) {
    return 'Do Project Gutenberg (e-book nº $id). Este livro está em domínio público nos Estados Unidos. As leis de direitos autorais variam de país para país, então verifique as do seu país antes de baixar.';
  }

  @override
  String get rightsStandardEbooks =>
      'Do Standard Ebooks, cujas edições estão em domínio público nos Estados Unidos e cujas próprias alterações são dedicadas ao domínio público (CC0). As leis de direitos autorais variam de país para país, então verifique as do seu país.';

  @override
  String get rightsWikisource =>
      'Do Wikisource, transcrito por voluntários; o EPUB é gerado pelo WS Export. O Wikisource abriga textos em domínio público e alguns com licenças livres (como CC BY-SA), que permitem ler e compartilhar livremente. Verifique as leis do seu país.';

  @override
  String rightsArchive(String year) {
    return 'Do Internet Archive. Só são listados livros publicados em $year ou antes, portanto em domínio público nos Estados Unidos. O texto do EPUB foi gerado automaticamente a partir de digitalizações e pode conter erros. As leis de direitos autorais variam de país para país, então verifique as do seu país.';
  }

  @override
  String addedToLibrary(String title) {
    return '“$title” foi adicionado à sua biblioteca';
  }

  @override
  String couldNotDownload(String title, String error) {
    return 'Não foi possível baixar “$title”: $error';
  }

  @override
  String get removeFromLibraryQuestion => 'Remover da biblioteca?';

  @override
  String removeFromLibraryBody(String title) {
    return '“$title” será removido da sua biblioteca e das suas estantes, junto com suas notas, destaques e marcadores. Você pode baixá-lo novamente a qualquer momento.';
  }

  @override
  String get continueReading => 'Continuar lendo';

  @override
  String get readNow => 'Ler agora';

  @override
  String get downloading => 'Baixando…';

  @override
  String downloadingPercent(int percent) {
    return 'Baixando $percent%';
  }

  @override
  String get noEbookEdition => 'Sem edição em e-book';

  @override
  String get freeToRead => 'Leitura livre';

  @override
  String get publicDomain => 'Domínio público';

  @override
  String downloadsCount(String count) {
    return '$count downloads';
  }

  @override
  String get getIllustratedEdition => 'Obter a edição ilustrada';

  @override
  String get illustratedDownloaded => 'Edição ilustrada baixada';

  @override
  String get removeDownload => 'Remover o download';

  @override
  String get removeFromLibrary => 'Remover da biblioteca';

  @override
  String get aboutThisBook => 'Sobre este livro';

  @override
  String get subjects => 'Assuntos';

  @override
  String get wantToRead => 'Quero ler';

  @override
  String get finished => 'Lido';

  @override
  String get addToShelf => 'Adicionar a uma estante';

  @override
  String onShelf(String name) {
    return 'Em “$name”';
  }

  @override
  String onShelves(int count) {
    return 'Em $count estantes';
  }

  @override
  String get newShelf => 'Nova estante';

  @override
  String get newShelfEllipsis => 'Nova estante…';

  @override
  String get shelfNameHint => 'ex.: Favoritos, Filosofia, Para ler';

  @override
  String get renameShelf => 'Renomear estante';

  @override
  String get deleteShelf => 'Excluir estante';

  @override
  String deleteShelfQuestion(String name) {
    return 'Excluir “$name”?';
  }

  @override
  String get deleteShelfBody =>
      'A estante é excluída; os livros dela continuam na sua biblioteca.';

  @override
  String get noShelvesYet =>
      'Você ainda não tem estantes. Crie uma para agrupar seus livros como quiser.';

  @override
  String bookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livros',
      one: '1 livro',
    );
    return '$_temp0';
  }

  @override
  String get bookDetails => 'Detalhes do livro';

  @override
  String get addToShelfEllipsis => 'Adicionar a uma estante…';

  @override
  String get removeFromWantToRead => 'Remover de “Quero ler”';

  @override
  String get markNotFinished => 'Marcar como não lido';

  @override
  String get markFinished => 'Marcar como lido';

  @override
  String downloadRemoved(String title) {
    return 'Download removido. “$title” continua na sua biblioteca com suas notas e sua posição.';
  }

  @override
  String get sort => 'Ordenar';

  @override
  String get filterHint => 'Filtrar por título ou autor';

  @override
  String get viewAll => 'Todos';

  @override
  String get viewDownloaded => 'Baixados';

  @override
  String get viewReading => 'Lendo';

  @override
  String get shelfHint =>
      'Clique com o botão direito ou toque e segure uma estante para renomeá-la ou excluí-la. Adicione livros com “Adicionar a uma estante” em qualquer livro.';

  @override
  String noBooksMatch(String query) {
    return 'Nenhum livro corresponde a “$query”.';
  }

  @override
  String get emptyShelf =>
      'Esta estante está vazia.\nAbra qualquer livro e escolha “Adicionar a uma estante”.';

  @override
  String get emptyDownloaded => 'Nenhum livro baixado.';

  @override
  String get emptyWantToRead =>
      'Ainda não há nada aqui.\nMarque livros do catálogo como “Quero ler”; eles são salvos sem serem baixados.';

  @override
  String get emptyReading => 'Você não está lendo nenhum livro no momento.';

  @override
  String get emptyFinished => 'Os livros que você terminar aparecem aqui.';

  @override
  String get emptyLibrary => 'Sua biblioteca está vazia.';

  @override
  String get sortRecent => 'Lidos recentemente';

  @override
  String get sortTitle => 'Título';

  @override
  String get sortAuthor => 'Autor';

  @override
  String get sortProgress => 'Progresso';

  @override
  String get sortAdded => 'Adicionados recentemente';

  @override
  String get tileNew => 'Novo';

  @override
  String get notDownloaded => 'Não baixado';

  @override
  String get note => 'Nota';

  @override
  String get writeNote => 'Escreva uma nota…';

  @override
  String get removeHighlight => 'Remover destaque';

  @override
  String get contents => 'Sumário';

  @override
  String bookmarksCount(int count) {
    return 'Marcadores ($count)';
  }

  @override
  String notesCount(int count) {
    return 'Notas ($count)';
  }

  @override
  String get unknownChapter => 'Capítulo desconhecido';

  @override
  String get noBookmarks =>
      'Ainda não há marcadores.\nUse o botão de marcador na barra de ferramentas (ou Ctrl+B).';

  @override
  String get bookmark => 'Marcador';

  @override
  String get deleteBookmark => 'Excluir marcador';

  @override
  String get noHighlights =>
      'Ainda não há destaques.\nSelecione um texto e escolha Destacar ou Nota. No computador, clique com o botão direito na seleção.';

  @override
  String get copyAllMarkdown => 'Copiar tudo em Markdown';

  @override
  String get notesCopied => 'Notas copiadas para a área de transferência';

  @override
  String get editNote => 'Editar nota';

  @override
  String get addNote => 'Adicionar nota';

  @override
  String get editHighlight => 'Editar destaque';

  @override
  String get highlight => 'Destacar';

  @override
  String get define => 'Definir';

  @override
  String get translate => 'Traduzir';

  @override
  String get closeImage => 'Fechar imagem';

  @override
  String bookOpenError(String error) {
    return 'Não foi possível abrir este livro.\n$error';
  }

  @override
  String get lessThanMinuteLeft => 'Menos de um minuto para o fim do capítulo';

  @override
  String minutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min para o fim do capítulo',
      one: '1 min para o fim do capítulo',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutesLeft(int hours, int minutes) {
    return '$hours h $minutes min para o fim do capítulo';
  }

  @override
  String finishedBook(String title) {
    return 'Você terminou “$title”. Ele agora está na sua lista de lidos.';
  }

  @override
  String get search => 'Pesquisar';

  @override
  String searchNoMatches(String query) {
    return '“$query” · nenhum resultado';
  }

  @override
  String searchPosition(String query, int index, int total) {
    return '“$query” · $index de $total';
  }

  @override
  String get previousMatch => 'Resultado anterior';

  @override
  String get nextMatch => 'Próximo resultado (F3)';

  @override
  String get closeSearch => 'Fechar pesquisa';

  @override
  String get theEnd => '— Fim —';

  @override
  String nextChapterTitle(String title) {
    return 'Próximo: $title';
  }

  @override
  String get backToLibrary => 'Voltar à biblioteca';

  @override
  String get searchInBookShortcut => 'Pesquisar no livro (Ctrl+F)';

  @override
  String get removeBookmarkShortcut => 'Remover marcador (Ctrl+B)';

  @override
  String get bookmarkPageShortcut => 'Marcar esta página (Ctrl+B)';

  @override
  String get contentsBookmarksNotes => 'Sumário, marcadores e notas';

  @override
  String get displaySettings => 'Configurações de exibição';

  @override
  String get previousChapter => 'Capítulo anterior';

  @override
  String get nextChapter => 'Próximo capítulo';

  @override
  String chapterStatus(String title, int index, int total, int percent) {
    return '$title  ·  Capítulo $index de $total  ·  $percent% lido';
  }

  @override
  String get searchInThisBook => 'Pesquisar neste livro';

  @override
  String get typeTwoLetters => 'Digite pelo menos duas letras.';

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Nenhum resultado',
    );
    return '$_temp0';
  }

  @override
  String matchesMany(int count) {
    return 'Mais de $count resultados';
  }

  @override
  String get translation => 'Tradução';

  @override
  String get noDefinition => 'Nenhuma definição encontrada.';

  @override
  String get translateInstead => 'Traduzir em vez disso';

  @override
  String get definitionsCredit =>
      'Definições do Wiktionary (CC BY-SA), em inglês.';

  @override
  String get translateInto => 'Para:';

  @override
  String get alreadyInLanguage =>
      'Este livro já está nesse idioma. Escolha outro acima.';

  @override
  String get translationCredit =>
      'Traduções do MyMemory. O texto selecionado é enviado ao serviço deles.';

  @override
  String get langAr => 'Árabe';

  @override
  String get langZh => 'Chinês';

  @override
  String get langNl => 'Holandês';

  @override
  String get langEn => 'Inglês';

  @override
  String get langFr => 'Francês';

  @override
  String get langDe => 'Alemão';

  @override
  String get langEl => 'Grego';

  @override
  String get langHe => 'Hebraico';

  @override
  String get langHi => 'Hindi';

  @override
  String get langIt => 'Italiano';

  @override
  String get langJa => 'Japonês';

  @override
  String get langKo => 'Coreano';

  @override
  String get langPl => 'Polonês';

  @override
  String get langPt => 'Português';

  @override
  String get langRu => 'Russo';

  @override
  String get langEs => 'Espanhol';

  @override
  String get langSv => 'Sueco';

  @override
  String get langTr => 'Turco';

  @override
  String get appLanguage => 'Idioma do app';

  @override
  String get sameAsDevice => 'Igual ao dispositivo';

  @override
  String get previewText =>
      'Foi o melhor dos tempos, foi o pior dos tempos; foi a era da sabedoria, foi a era da tolice.';

  @override
  String get sectionText => 'Texto';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSepia => 'Sépia';

  @override
  String get themeDark => 'Escuro';

  @override
  String get fontDescSerif =>
      'Literata: uma fonte serifada criada para leitura na tela.';

  @override
  String get fontDescGaramond =>
      'EB Garamond: um tipo clássico de livro, baseado em tipos do século XVI.';

  @override
  String get fontDescSans =>
      'Atkinson Hyperlegible: uma fonte sem serifa criada pelo Braille Institute para que letras parecidas sejam fáceis de distinguir.';

  @override
  String get fontDescDyslexic =>
      'OpenDyslexic tem a base das letras mais pesada para ajudar a evitar que elas se invertam ou se troquem. Muitos leitores também preferem mais espaço entre as letras e texto não justificado.';

  @override
  String get textSize => 'Tamanho do texto';

  @override
  String get lineSpacing => 'Espaçamento entre linhas';

  @override
  String get letterSpacing => 'Espaçamento entre letras';

  @override
  String get normal => 'Normal';

  @override
  String get justifyText => 'Justificar o texto';

  @override
  String get justifySubtitle =>
      'Margem direita alinhada. Desative para espaços iguais entre as palavras.';

  @override
  String get sectionPage => 'Página';

  @override
  String get margins => 'Margens';

  @override
  String get lineWidth => 'Largura da linha';

  @override
  String get lineWidthHint =>
      'Linhas mais curtas são mais fáceis de acompanhar; a coluna de texto nunca é mais larga que a tela menos as margens.';

  @override
  String get sectionScreen => 'Tela';

  @override
  String get brightness => 'Brilho';

  @override
  String get warmth => 'Temperatura';

  @override
  String get off => 'Desativado';

  @override
  String get screenHint =>
      'O brilho e a temperatura valem para todo o app, além das configurações do seu dispositivo. A temperatura reduz a luz azul, como um modo noturno.';

  @override
  String readingSpeed(int wpm) {
    return 'Velocidade de leitura: cerca de $wpm palavras por minuto (aprendida enquanto você lê).';
  }

  @override
  String get resetDefaults => 'Restaurar padrões';

  @override
  String errCatalogHttp(int status) {
    return 'O catálogo retornou um erro ($status).';
  }

  @override
  String get errSearchFailed => 'A pesquisa falhou.';

  @override
  String get errNoOtherEdition => 'Não há outra edição deste livro.';

  @override
  String get errNoEpub =>
      'Este título não tem edição em e-book (pode ser um audiolivro).';

  @override
  String get errDownloadTimeout =>
      'O download demorou demais. Verifique sua conexão e tente novamente.';

  @override
  String errDownloadHttp(int status) {
    return 'O download falhou ($status).';
  }

  @override
  String get errInvalidEpub => 'O arquivo baixado não é um EPUB válido.';

  @override
  String get errWikisourceTooLong =>
      'O Wikisource não conseguiu preparar este livro: ele é longo demais para o serviço de EPUB. Tente um dos volumes ou procure-o em outro catálogo.';

  @override
  String errDictionary(int status) {
    return 'O dicionário não está disponível ($status).';
  }

  @override
  String errTranslationUnavailable(int status) {
    return 'A tradução não está disponível ($status).';
  }

  @override
  String get errTranslationQuota =>
      'O limite diário de traduções gratuitas foi atingido.';

  @override
  String errTranslationFailed(int status) {
    return 'A tradução falhou ($status).';
  }

  @override
  String errSourceBusy(String host) {
    return '$host está ocupado; tente novamente em um minuto.';
  }

  @override
  String errSourceHttp(String host, int status) {
    return '$host retornou um erro ($status).';
  }

  @override
  String get errTimeout =>
      'A conexão demorou demais. Verifique sua conexão com a internet e tente novamente.';

  @override
  String get errGeneric => 'Algo deu errado. Tente novamente.';
}
