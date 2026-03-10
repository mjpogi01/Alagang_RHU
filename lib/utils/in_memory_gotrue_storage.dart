import 'package:gotrue/gotrue.dart';

/// In-memory implementation of [GotrueAsyncStorage] for use on Flutter web
/// where SharedPreferences is not available. PKCE state is not persisted
/// across page reloads.
class InMemoryGotrueAsyncStorage extends GotrueAsyncStorage {
  InMemoryGotrueAsyncStorage() : _storage = {};

  final Map<String, String> _storage;

  @override
  Future<String?> getItem({required String key}) async => _storage[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _storage.remove(key);
  }
}
