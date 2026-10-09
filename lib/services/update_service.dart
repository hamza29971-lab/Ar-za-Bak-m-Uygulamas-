// lib/services/update_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kiosk_service.dart';

/// Güncellemeler herkese açık GitHub deposundan anahtarsız alınır. Uygulamaya
/// gömülü bir anahtar iptal edildiğinde kurulu tabletler bir daha güncelleme
/// alamıyordu; açık depoda iptal edilecek bir anahtar yoktur.
class UpdateService {
  static const String _owner = 'hamza29971-lab';
  static const String _repo = 'Nimo_bak-m_g-ncelleme';
  static const String _ignoredKey = 'last_ignored_build_nimo';

  /// GitHub API yerine doğrudan dosya adresi kullanılır: API anahtarsız
  /// isteklerde IP başına saatte 60 istekle sınırlı, tabletler ise 30
  /// saniyede bir kontrol ediyor.
  static const String _rawBase =
      'https://raw.githubusercontent.com/$_owner/$_repo/main';

  /// `version.json`'da `apk` alanı yoksa indirilen dosya.
  static const String _fallbackApk = 'latest.apk';

  /// Depodaki yayın: `{"build_number": 93, "apk": "nimo_93.apk"}`.
  ///
  /// GitHub'ın dosya sunucusu dosyaları ~5 dakika önbellekte tutuyor ve
  /// sorgu parametresini yok sayıyor. APK hep aynı adla yüklenseydi tablet
  /// yeni numarayı görüp önbellekteki eski APK'yı indirebilirdi; her sürüm
  /// kendi adıyla yüklendiğinde bu olamaz.
  static Future<({int build, String apk})> getRemoteRelease() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_rawBase/version.json?t=$ts');
    final response = await http.get(url, headers: const <String, String>{
      'Cache-Control': 'no-cache',
    });
    if (response.statusCode == 200) {
      final Object? data = jsonDecode(response.body);
      if (data is Map && data['build_number'] is num) {
        return (
          build: (data['build_number'] as num).toInt(),
          apk: apkFileFrom(data),
        );
      }
      throw Exception('version.json biçimi hatalı: ${response.body}');
    }
    throw Exception('version.json okunamadi: ${response.statusCode}');
  }

  /// `apk` alanındaki dosya adı. Yalnızca düz bir `.apk` dosya adı kabul
  /// edilir (klasör ya da adres değil); geçersizse [_fallbackApk].
  @visibleForTesting
  static String apkFileFrom(Map<dynamic, dynamic> data) {
    final Object? apk = data['apk'];
    if (apk is String && RegExp(r'^[A-Za-z0-9._-]+\.apk$').hasMatch(apk.trim())) {
      return apk.trim();
    }
    return _fallbackApk;
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

  static Future<({bool available, int remoteBuild, String apkFile})> checkUpdate() async {
    const none = (available: false, remoteBuild: 0, apkFile: _fallbackApk);
    try {
      final int? installed = await KioskService.instance.installedVersionCode();
      if (installed == null) return none;

      final remote = await getRemoteRelease();
      final prefs = await SharedPreferences.getInstance();
      final ignored = prefs.getInt(_ignoredKey) ?? 0;

      return (
        available: shouldOffer(remote: remote.build, installed: installed, ignored: ignored),
        remoteBuild: remote.build,
        apkFile: remote.apk,
      );
    } catch (e) {
      debugPrint('[Update] güncelleme kontrolü başarısız: $e');
      return none;
    }
  }

  /// APK'yi indirir ve indirme ilerlemesini bildirir (0.0 - 1.0).
  ///
  /// Dosya belleğe alınmadan doğrudan diske yazılır: ~85 MB'lık APK'yı bir
  /// `List<int>` içinde biriktirmek yüzlerce MB RAM harcıyordu.
  static Future<File> downloadApk(
    int newBuildNumber,
    String apkFile,
    void Function(double progress) onProgress,
  ) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_rawBase/$apkFile?t=$ts');

    final response = await http.Request('GET', url).send();
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
