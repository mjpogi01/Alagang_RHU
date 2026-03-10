import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'utils/auth_deep_link.dart';
import 'utils/in_memory_gotrue_storage.dart';
import 'widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web, SharedPreferences causes MissingPluginException. Use in-memory/empty
  // storage so auth works; session won't persist across page refresh.
  final authOptions = kIsWeb
      ? FlutterAuthClientOptions(
          localStorage: const EmptyLocalStorage(),
          pkceAsyncStorage: InMemoryGotrueAsyncStorage(),
        )
      : const FlutterAuthClientOptions();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: authOptions,
  );
  // Handle email confirmation / magic link that opened the app (mobile deep link)
  if (!kIsWeb) {
    await AuthDeepLink.handleInitialLink();
  }
  await initializeDateFormatting('en');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AlagangRHUApp());
}

class AlagangRHUApp extends StatefulWidget {
  const AlagangRHUApp({super.key});

  @override
  State<AlagangRHUApp> createState() => _AlagangRHUAppState();
}

class _AlagangRHUAppState extends State<AlagangRHUApp> {
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _linkSubscription = AuthDeepLink.listenToLinks(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alagang RHU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
