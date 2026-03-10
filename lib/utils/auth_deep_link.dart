import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles auth deep links (e.g. email confirmation) so the app opens and the session is set.
/// Call [handleInitialLink] after Supabase.initialize() and [listenToLinks] when app is running.
class AuthDeepLink {
  AuthDeepLink._();

  static const String _scheme = 'alagangrhu';
  static const String _host = 'auth';

  /// True when session was just set from an email-confirmation deep link (show confirmation screen).
  static bool _justConfirmedEmail = false;
  static bool get justConfirmedEmail => _justConfirmedEmail;
  static void clearJustConfirmedEmail() {
    _justConfirmedEmail = false;
  }

  static bool _isAuthCallback(Uri uri) {
    return uri.scheme == _scheme && (uri.host.isEmpty || uri.host == _host);
  }

  static Future<void> _setSessionFromUri(Uri uri) async {
    // Tokens can be in fragment (#...) or query (?...) after redirect from Supabase
    final fragment = uri.fragment;
    final query = uri.query;
    final params = <String, String>{};
    if (fragment.isNotEmpty) {
      for (final p in fragment.split('&')) {
        final kv = p.split('=');
        if (kv.length == 2) params[Uri.decodeComponent(kv[0])] = Uri.decodeComponent(kv[1]);
      }
    }
    if (query.isNotEmpty) {
      for (final p in query.split('&')) {
        final kv = p.split('=');
        if (kv.length == 2) params[Uri.decodeComponent(kv[0])] = Uri.decodeComponent(kv[1]);
      }
    }
    final refreshToken = params['refresh_token'];
    final type = params['type'];
    final hasConfirmSignal =
        type != null || params.containsKey('token') || params.containsKey('token_hash');

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await Supabase.instance.client.auth.setSession(refreshToken);
      _justConfirmedEmail = true;
    } else if (hasConfirmSignal) {
      // Email was confirmed but no session tokens were returned.
      _justConfirmedEmail = true;
    }
  }

  static Uri? _toUri(dynamic value) {
    if (value == null) return null;
    if (value is Uri) return value;
    if (value is String) return Uri.tryParse(value);
    return null;
  }

  /// Call once after Supabase.initialize() to handle the link that launched the app (e.g. from email).
  static Future<void> handleInitialLink() async {
    try {
      final appLinks = AppLinks();
      final value = await appLinks.getInitialLink();
      final uri = _toUri(value);
      if (uri != null && _isAuthCallback(uri)) {
        await _setSessionFromUri(uri);
      }
    } catch (_) {
      // getInitialLink can throw on web or if plugin not ready; ignore
    }
  }

  /// Listen for auth links while the app is open (e.g. user switches back and taps link again).
  static StreamSubscription? listenToLinks(void Function() onSessionSet) {
    try {
      final appLinks = AppLinks();
      return appLinks.uriLinkStream.listen((value) async {
        final uri = _toUri(value);
        if (uri != null && _isAuthCallback(uri)) {
          await _setSessionFromUri(uri);
          onSessionSet();
        }
      });
    } catch (_) {
      return null;
    }
  }
}
