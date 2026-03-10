import 'package:supabase_flutter/supabase_flutter.dart';

/// Central access to Supabase client and database helpers.
///
/// Use [SupabaseService.client] for database queries and auth.
/// Example:
///   final user = SupabaseService.client.auth.currentUser;
///   final data = await SupabaseService.client.from('table_name').select();
class SupabaseService {
  SupabaseService._();

  /// The Supabase client (initialized in main.dart).
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut for auth.
  static GoTrueClient get auth => client.auth;
}
