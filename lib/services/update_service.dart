// lib/services/update_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kiosk_service.dart';

class UpdateService {
  static const String _token1 = 'ghp_1seMoPinB3kQjaml';
  static const String _token2 = '4fAY4gblfmNnHI14atAX';
  static String get _token => _token1 + _token2;

  static const String _owner = 'hamza29971-lab';
  static const String _repo = 'Nimo_bak-m_g-ncelleme';
  static const String _ignoredKey = 'last_ignored_build_nimo';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/vnd.github.raw+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  /// GitHub daki build_number i getirir (cache bypass ile)
  static Future<int> getRemoteBuildNumber() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/contents/version.json?t=$ts');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['build_number'] as num).toInt();
    }
    throw Exception('version.json okunamadi: ${response.statusCode}');
  }

  /// Kullanıcı 'Şimdi Değil' derse, bu build numarasını bir daha sormaması için kaydeder.
  static Future<void> ignoreBuild(int buildNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ignoredKey, buildNumber);
  }

  /// Güncelleme önerilmeli mi?
  ///
  /// Karşılaştırma tabletteki GERÇEK versionCode ile yapılır; indirme ya da
  /// kurulum denemesi hiçbir şeyi "kuruldu" saymaz. Böylece başarısız bir
  /// kurulum sonraki kontrolde yeniden önerilir. Daha eski bir sürüm hiçbir
  /// zaman önerilmez (Android zaten reddeder).
  @visibleForTesting
  static bool shouldOffer({
    required int remote,
    required int installed,
    required int ignored,
  }) =>
      remote > installed && remote != ignored;

  static Future<({bool available, int remoteBuild})> checkUpdate() async {
    try {
      final int? installed = await KioskService.instance.installedVersionCode();
      if (installed == null) return (available: false, remoteBuild: 0);

      final remote = await getRemoteBuildNumber();
      final prefs = await SharedPreferences.getInstance();
      final ignored = prefs.getInt(_ignoredKey) ?? 0;

      return (
        available: shouldOffer(remote: remote, installed: installed, ignored: ignored),
        remoteBuild: remote,
      );
    } catch (_) {
      return (available: false, remoteBuild: 0);
    }
  }

  /// APK'yi indirir ve indirme ilerlemesini bildirir (0.0 - 1.0).
  ///
  /// Dosya belleğe alınmadan doğrudan diske yazılır: ~85 MB'lık APK'yı bir
  /// `List<int>` içinde biriktirmek yüzlerce MB RAM harcıyordu.
  static Future<File> downloadApk(
      int newBuildNumber, void Function(double progress) onProgress) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse(
        'https://raw.githubusercontent.com/$_owner/$_repo/main/latest.apk?t=$ts');

    final request = http.Request('GET', url);
    request.headers.addAll({
      'Authorization': 'Bearer $_token',
    });

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('APK indirilemedi: ${response.statusCode}');
    }

    final dir = await getExternalStorageDirectory();
    if (dir == null) throw Exception('İndirme klasörü bulunamadı.');

    // Eski kurulum dosyalarını temizle
    for (final f in dir.listSync()) {
      if (f is File && f.path.contains('nimo_update_')) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }

    final file = File('${dir.path}/nimo_update_$newBuildNumber.apk');
    final IOSink sink = file.openWrite();
    final contentLength = response.contentLength ?? 0;
    int downloaded = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) onProgress(downloaded / contentLength);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return file;
  }
}
