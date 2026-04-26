import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Local credentials storage (passwords in plain text — acceptable for offline demo only).
class HiveAuthRepository implements AuthRepository {
  static const _kUsers = 'users';
  static const _kSession = 'session_login_key';
  static const _kNotifications = 'notifications_enabled';

  static const demoEmail = 'demo@autopilot.com';
  static const demoPassword = '123456';
  static const demoName = 'Demo User';

  Box<dynamic>? _box;

  Future<Box<dynamic>> _open() async {
    _box ??= await Hive.openBox(HiveBoxes.auth);
    return _box!;
  }

  Map<String, Map<String, dynamic>> _readUsers(Box<dynamic> box) {
    final raw = box.get(_kUsers);
    if (raw is! Map) return {};
    return raw.map((k, v) {
      final key = k.toString();
      if (v is Map) {
        return MapEntry(key, Map<String, dynamic>.from(v.map((a, b) => MapEntry(a.toString(), b))));
      }
      return MapEntry(key, <String, dynamic>{});
    });
  }

  Future<void> _writeUsers(Box<dynamic> box, Map<String, Map<String, dynamic>> users) async {
    await box.put(_kUsers, users);
  }

  @override
  Future<void> ensureInitialized() async {
    final box = await _open();
    var users = _readUsers(box);
    final demoKey = demoEmail.toLowerCase();
    if (!users.containsKey(demoKey)) {
      users = Map<String, Map<String, dynamic>>.from(users);
      users[demoKey] = {
        'name': demoName,
        'password': demoPassword,
      };
      await _writeUsers(box, users);
    }
    if (box.get(_kNotifications) == null) {
      await box.put(_kNotifications, true);
    }
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    final box = await _open();
    final key = box.get(_kSession) as String?;
    if (key == null) return null;
    final users = _readUsers(box);
    final u = users[key];
    if (u == null) return null;
    final name = u['name'] as String? ?? '';
    return AuthSession(loginKey: key, name: name);
  }

  @override
  Future<AuthSession?> login(String loginId, String password) async {
    final box = await _open();
    final key = _normalizeLoginId(loginId);
    if (key.isEmpty) return null;
    final users = _readUsers(box);
    final u = users[key];
    if (u == null) return null;
    final stored = u['password'] as String? ?? '';
    if (stored != password) return null;
    await box.put(_kSession, key);
    final name = u['name'] as String? ?? '';
    return AuthSession(loginKey: key, name: name);
  }

  @override
  Future<void> register({
    required String name,
    required String loginId,
    required String password,
  }) async {
    final box = await _open();
    final key = _normalizeLoginId(loginId);
    final users = Map<String, Map<String, dynamic>>.from(_readUsers(box));
    if (users.containsKey(key)) {
      throw Exception('An account already exists for this email or phone.');
    }
    users[key] = {
      'name': name.trim(),
      'password': password,
    };
    await _writeUsers(box, users);
  }

  @override
  Future<void> logout() async {
    final box = await _open();
    await box.delete(_kSession);
  }

  @override
  Future<void> updateSessionName(String name) async {
    final box = await _open();
    final key = box.get(_kSession) as String?;
    if (key == null) return;
    final users = Map<String, Map<String, dynamic>>.from(_readUsers(box));
    final u = users[key];
    if (u == null) return;
    u['name'] = name.trim();
    users[key] = u;
    await _writeUsers(box, users);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final box = await _open();
    final v = box.get(_kNotifications);
    if (v is bool) return v;
    return true;
  }

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    final box = await _open();
    await box.put(_kNotifications, value);
  }

  static String _normalizeLoginId(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.contains('@')) return s.toLowerCase();
    final digits = s.replaceAll(RegExp(r'\D'), '');
    return digits;
  }
}
