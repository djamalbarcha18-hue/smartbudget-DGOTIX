import 'package:flutter/foundation.dart';

/// Authenticated user (domain entity).
///
/// Backend-agnostic: mapped from whichever provider (Supabase / fake) is active.
/// Holds identity only — never financial data.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? displayName;

  /// The Google account picture, when the user signed in with Google.
  /// Loaded by the device straight from Google: never stored by the app.
  final String? avatarUrl;

  /// Accepts a picture address only when it is served by Google's picture
  /// host over https; anything else (the account's metadata is editable by
  /// its owner) is ignored and the initial is shown instead.
  static String? googleAvatarUrl(Object? raw) {
    if (raw is! String) return null;
    final Uri? uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'https') return null;
    if (uri.host != avatarHost || uri.hasPort || uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.toString();
  }

  /// The only host a profile picture may come from (see web/index.html).
  static const String avatarHost = 'lh3.googleusercontent.com';

  /// Best-effort display name (falls back to the email's local part).
  String get name {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    final int at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, email, displayName, avatarUrl);
}
