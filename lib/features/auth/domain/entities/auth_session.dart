/// Logged-in user snapshot (backed by Hive auth store).
class AuthSession {
  const AuthSession({
    required this.loginKey,
    required this.name,
  });

  /// Normalized identifier: lowercased email, or digits-only phone.
  final String loginKey;
  final String name;

  /// Shown in UI (email as-is; phone as stored digits — optional formatting later).
  String get displayIdentifier => loginKey;
}
