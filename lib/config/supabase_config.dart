/// Supabase project configuration.
///
/// Anon key: Supabase Dashboard → Project Settings → API → anon public key.
/// (Do not use the PostgreSQL connection string or database password in the app.)
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL for this project.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qkdrvnekvejrwzlnskxm.supabase.co',
  );

  /// Anon (public) key from Dashboard → Project Settings → API. Safe to use in the app.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_HZ1wPkGCEsLYZmIq7kP8XQ_emw4EMFn',
  );
}
