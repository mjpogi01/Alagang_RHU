import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/welcome_screen.dart';
import '../app_shell.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

/// Shows [WelcomeScreen] when not signed in, [AppShell] when signed in.
/// Waits briefly for session restore on hot restart so we don't flash WelcomeScreen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _restoreTimer;
  bool _allowLoggedOut = false;
  bool _syncedPushToken = false;

  @override
  void initState() {
    super.initState();
    // Give persisted session time to restore after hot restart (e.g. 800ms).
    _restoreTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _allowLoggedOut = true);
    });
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          _allowLoggedOut = true;
          if (!_syncedPushToken) {
            _syncedPushToken = true;
            // Best-effort: sync token and keep app running even if Firebase isn't configured yet.
            NotificationService.syncTokenIfLoggedIn();
          }
          return const AppShell();
        }
        // Don't show WelcomeScreen until we've allowed time for session restore (avoids logout on hot restart).
        if (!_allowLoggedOut) {
          return const Scaffold(
            backgroundColor: AppTheme.surfaceWhite,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const WelcomeScreen();
      },
    );
  }
}
