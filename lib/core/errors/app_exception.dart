/// Base exception class for Vibe Check.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => '$runtimeType: $message${code != null ? ' ($code)' : ''}';
}

/// Thrown when importing or parsing fails.
class ParsingException extends AppException {
  final int? lineNumber;

  const ParsingException(
    super.message, {
    super.code,
    super.details,
    this.lineNumber,
  });
}

/// Thrown when chat validation criteria fail (e.g. fewer than 10 messages).
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

/// Thrown during AI pipeline execution or backend communication.
class AiServiceException extends AppException {
  final bool isRetryable;

  const AiServiceException(
    super.message, {
    super.code,
    super.details,
    this.isRetryable = false,
  });
}

/// Thrown when local storage operations fail.
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.details});
}

/// Thrown when in-app purchase or entitlement verification fails.
class SubscriptionException extends AppException {
  const SubscriptionException(super.message, {super.code, super.details});
}
