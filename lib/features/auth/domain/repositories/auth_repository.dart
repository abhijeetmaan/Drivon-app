import '../entities/auth_session.dart';

abstract class AuthRepository {
  /// Seeds demo user and opens box.
  Future<void> ensureInitialized();

  Future<AuthSession?> getCurrentSession();

  /// Returns null if credentials invalid.
  Future<AuthSession?> login(String loginId, String password);

  /// Throws if [loginId] already registered.
  Future<void> register({
    required String name,
    required String loginId,
    required String password,
  });

  Future<void> logout();

  /// Updates display name for the current session and stored user record.
  Future<void> updateSessionName(String name);

  /// Whether push reminders are enabled (local setting).
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool value);
}
