import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../auth_validators.dart';
import '../../data/repositories/hive_auth_repository.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HiveAuthRepository();
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(AuthNotifier.new);

final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  await repo.ensureInitialized();
  return repo.getNotificationsEnabled();
});

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.ensureInitialized();
    return repo.getCurrentSession();
  }

  /// Validates credentials and syncs profile — does **not** switch app shell (for success animations).
  Future<AuthSession?> attemptLogin(String loginId, String password) async {
    final repo = ref.read(authRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final session = await repo.login(loginId, password);
    if (session == null) return null;
    await _syncProfileFromSession(session, profileRepo);
    return session;
  }

  /// Call after cinematic success animation to enter the main app.
  void commitSession(AuthSession session) {
    state = AsyncData(session);
  }

  Future<void> login(String loginId, String password) async {
    final session = await attemptLogin(loginId, password);
    if (session == null) {
      throw const AuthFailure('Invalid email/phone or password.');
    }
    commitSession(session);
  }

  Future<AuthSession> attemptSignup({
    required String name,
    required String loginId,
    required String password,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    try {
      await repo.register(name: name, loginId: loginId, password: password);
    } on Exception catch (e) {
      throw AuthFailure(e.toString().replaceFirst('Exception: ', ''));
    }
    final session = await repo.login(loginId, password);
    if (session == null) {
      throw const AuthFailure('Could not sign you in. Try again.');
    }
    final key = normalizeLoginId(loginId);
    final isEmail = loginId.trim().contains('@');
    await profileRepo.saveProfile(
      UserProfile(
        name: name.trim(),
        email: isEmail ? key : '',
        phone: isEmail ? null : key,
      ),
    );
    return session;
  }

  Future<void> signup({
    required String name,
    required String loginId,
    required String password,
  }) async {
    final session = await attemptSignup(
      name: name,
      loginId: loginId,
      password: password,
    );
    commitSession(session);
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(null);
  }

  Future<void> refreshSession() async {
    final repo = ref.read(authRepositoryProvider);
    final s = await repo.getCurrentSession();
    state = AsyncData(s);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await ref.read(authRepositoryProvider).setNotificationsEnabled(value);
    ref.invalidate(notificationsEnabledProvider);
  }
}

Future<void> _syncProfileFromSession(AuthSession session, ProfileRepository profileRepo) async {
  final existing = await profileRepo.getProfile();
  final isEmail = session.loginKey.contains('@');
  final idMatches = existing != null &&
      ((isEmail && existing.email == session.loginKey) ||
          (!isEmail && existing.phone == session.loginKey));
  final e = existing;
  final next = UserProfile(
    name: session.name,
    email: isEmail ? session.loginKey : (idMatches && e != null ? e.email : ''),
    phone: isEmail ? (idMatches && e != null ? e.phone : null) : session.loginKey,
    avatarPath: idMatches && e != null ? e.avatarPath : null,
  );
  if (existing == null ||
      existing.name != next.name ||
      existing.email != next.email ||
      existing.phone != next.phone ||
      existing.avatarPath != next.avatarPath) {
    await profileRepo.saveProfile(next);
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}
