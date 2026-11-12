/// What went wrong, as a code the interface turns into a sentence in the
/// reader's language (see `lib/l10n/l10n_helpers.dart`).
enum ErrorCode {
  catalogHttp,
  searchFailed,
  noOtherEdition,
  noEpub,
  downloadTimeout,
  downloadHttp,
  invalidEpub,
  wikisourceTooLong,
  dictionaryUnavailable,
  translationUnavailable,
  translationQuota,
  translationFailed,
  sourceBusy,
  sourceHttp,
}

/// Base of the app's own exceptions. [status] is an HTTP status, [host] the
/// server involved, and [detail] a message from a service, passed through as is.
class AppException implements Exception {
  final ErrorCode code;
  final int? status;
  final String? host;
  final String? detail;
  const AppException(this.code, {this.status, this.host, this.detail});

  /// For logs and tests; the interface localizes [code] instead.
  String get message =>
      detail ?? '${code.name}${status == null ? '' : ' ($status)'}';

  @override
  String toString() => message;
}
