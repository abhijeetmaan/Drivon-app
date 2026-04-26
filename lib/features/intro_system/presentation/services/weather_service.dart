import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';

enum WeatherKind { sunny, cloudy, rainy, unknown }

class WeatherInfo {
  final WeatherKind kind;
  final double? temperatureC;
  final String? placeLabel;

  const WeatherInfo({
    required this.kind,
    this.temperatureC,
    this.placeLabel,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        't': temperatureC,
        'place': placeLabel,
      };

  static WeatherInfo fromJson(Map<String, dynamic> json) {
    final k = WeatherKind.values.where((e) => e.name == json['kind']).cast<WeatherKind?>().firstOrNull ?? WeatherKind.unknown;
    final t = json['t'];
    return WeatherInfo(
      kind: k,
      temperatureC: t is num ? t.toDouble() : null,
      placeLabel: json['place'] is String ? json['place'] as String : null,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class WeatherService {
  static const _cacheKey = 'intro_weather_cache_v1';
  static const _cacheMsKey = 'intro_weather_cache_ms_v1';
  static const _ttlMs = 30 * 60 * 1000; // 30 min

  static WeatherInfo? readCachedSync() {
    if (!Hive.isBoxOpen(HiveBoxes.appPrefs)) return null;
    final box = Hive.box<dynamic>(HiveBoxes.appPrefs);
    final ms = box.get(_cacheMsKey);
    if (ms is int) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - ms > _ttlMs) return null;
    } else {
      return null;
    }
    final raw = box.get(_cacheKey);
    if (raw is String) {
      try {
        final m = jsonDecode(raw);
        if (m is Map<String, dynamic>) return WeatherInfo.fromJson(m);
      } catch (_) {}
    }
    return null;
  }

  static Future<WeatherInfo?> fetchAndCacheBestEffort() async {
    if (!Hive.isBoxOpen(HiveBoxes.appPrefs)) return null;
    // Avoid network work in widget tests.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    final cached = readCachedSync();
    if (cached != null) return cached;

    try {
      final loc = await _fetchApproxLocationFromIp();
      if (loc == null) return null;
      final wx = await _fetchOpenMeteo(lat: loc.lat, lon: loc.lon);
      if (wx == null) return null;

      final info = WeatherInfo(
        kind: wx.kind,
        temperatureC: wx.temperatureC,
        placeLabel: loc.city,
      );

      final box = Hive.box<dynamic>(HiveBoxes.appPrefs);
      await box.put(_cacheKey, jsonEncode(info.toJson()));
      await box.put(_cacheMsKey, DateTime.now().millisecondsSinceEpoch);
      return info;
    } catch (_) {
      return null;
    }
  }

  static Future<_IpLocation?> _fetchApproxLocationFromIp() async {
    // Best-effort, no permissions; may fail in restricted networks.
    final uri = Uri.parse('https://ipapi.co/json/');
    final body = await _httpGet(uri, timeoutSeconds: 3);
    if (body == null) return null;
    final json = jsonDecode(body);
    if (json is! Map) return null;
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (lat is! num || lon is! num) return null;
    final city = json['city'] is String ? json['city'] as String : null;
    return _IpLocation(lat: lat.toDouble(), lon: lon.toDouble(), city: city);
  }

  static Future<_OpenMeteoCurrent?> _fetchOpenMeteo({required double lat, required double lon}) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
    );
    final body = await _httpGet(uri, timeoutSeconds: 3);
    if (body == null) return null;
    final json = jsonDecode(body);
    if (json is! Map) return null;
    final current = json['current_weather'];
    if (current is! Map) return null;
    final code = current['weathercode'];
    final temp = current['temperature'];
    final kind = _mapWeatherCode(code is num ? code.toInt() : null);
    return _OpenMeteoCurrent(
      kind: kind,
      temperatureC: temp is num ? temp.toDouble() : null,
    );
  }

  static WeatherKind _mapWeatherCode(int? code) {
    if (code == null) return WeatherKind.unknown;
    if (code == 0) return WeatherKind.sunny;
    if (code == 1 || code == 2 || code == 3 || code == 45 || code == 48) return WeatherKind.cloudy;
    // Drizzle/rain/snow/thunder → rainy vibe for intro.
    if (code >= 51) return WeatherKind.rainy;
    return WeatherKind.unknown;
  }

  static Future<String?> _httpGet(Uri uri, {required int timeoutSeconds}) async {
    final client = HttpClient();
    client.connectionTimeout = Duration(seconds: timeoutSeconds);
    try {
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'AutoPilotIntro/1.0');
      final resp = await req.close().timeout(Duration(seconds: timeoutSeconds));
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
      return await resp.transform(utf8.decoder).join().timeout(Duration(seconds: timeoutSeconds));
    } finally {
      client.close(force: true);
    }
  }
}

class _IpLocation {
  final double lat;
  final double lon;
  final String? city;
  const _IpLocation({required this.lat, required this.lon, required this.city});
}

class _OpenMeteoCurrent {
  final WeatherKind kind;
  final double? temperatureC;
  const _OpenMeteoCurrent({required this.kind, required this.temperatureC});
}

