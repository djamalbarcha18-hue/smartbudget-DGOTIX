/// Provider-agnostic error taxonomy and the failover policy.
///
/// The policy decides whether a failure may be retried on another model/provider
/// (transient/availability problems) or must stop immediately (the request or
/// key is wrong, or the model can't do the task). This prevents blindly
/// hammering every provider on a permanent error.
library;

enum AiErrorKind {
  // Do NOT fail over on these — the problem follows to the next provider.
  invalidRequest,
  invalidApiKey,
  unsupportedCapability,
  blocked,

  // MAY fail over on these — transient / availability.
  timeout,
  providerUnavailable,
  rateLimited,
  quotaExceeded,
  serverError,

  // Neutral.
  empty,
  unknown,
}

extension AiErrorKindX on AiErrorKind {
  /// Whether the failover policy allows trying another model/provider.
  bool get isRetryable => switch (this) {
        AiErrorKind.timeout ||
        AiErrorKind.providerUnavailable ||
        AiErrorKind.rateLimited ||
        AiErrorKind.quotaExceeded ||
        AiErrorKind.serverError =>
          true,
        _ => false,
      };

  /// Maps an HTTP status + optional provider message to a kind.
  static AiErrorKind fromHttp(int status, {String message = ''}) {
    final String m = message.toLowerCase();
    if (status == 401 ||
        status == 403 ||
        m.contains('api key') ||
        m.contains('api_key_invalid') ||
        m.contains('permission')) {
      return AiErrorKind.invalidApiKey;
    }
    if (status == 429) {
      return m.contains('quota')
          ? AiErrorKind.quotaExceeded
          : AiErrorKind.rateLimited;
    }
    if (status == 400) {
      // A missing model / unsupported feature is not a key problem.
      if (m.contains('not found') ||
          m.contains('not supported') ||
          m.contains('unsupported')) {
        return AiErrorKind.unsupportedCapability;
      }
      return AiErrorKind.invalidRequest;
    }
    if (status == 404) return AiErrorKind.unsupportedCapability;
    if (status == 408 || status == 504) return AiErrorKind.timeout;
    if (status == 503) return AiErrorKind.providerUnavailable;
    if (status >= 500) return AiErrorKind.serverError;
    return AiErrorKind.unknown;
  }
}

/// A provider-agnostic failure. [detail] is the provider's own message (never a
/// key), surfaced for diagnostics; the UI shows a generic message to the user.
class AiFailure implements Exception {
  const AiFailure(this.kind, {this.detail, this.provider, this.model});
  final AiErrorKind kind;
  final String? detail;
  final String? provider;
  final String? model;

  bool get isRetryable => kind.isRetryable;

  @override
  String toString() =>
      'AiFailure($kind${model == null ? '' : ' model=$model'}'
      '${detail == null ? '' : ': $detail'})';
}
