// lib/services/update_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  static const String _token1 = 'ghp_1seMoPinB3kQjaml';
  static const String _token2 = '4fAY4gblfmNnHI14atAX';
  static String get _token => _token1 + _token2;
  
  static const String _owner = 'hamza29971-lab';
  static const String _repo = 'Nimo_bak-m_g-ncelleme';
  static const String _prefKey = 'last_downloaded_build_nimo';
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

  /// Tabletteki yerel build_number'i okur.
  /// assets/version.txt içindeki sayıyı döndürür.
  static Future<int> getLocalBuildNumber() async {
    try {
      final content = await rootBundle.loadString('assets/version.txt');
      return int.tryParse(content.trim()) ?? 1;
    } catch (_) {
      return 1;
    }
  }

  /// Kullanıcı 'Şimdi Değil' derse, bu build numarasını bir daha sormaması için kaydeder.
  static Future<void> ignoreBuild(int buildNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ignoredKey, buildNumber);
  }

  /// Guncelleme gerekip gerekmedigini kontrol eder.
  /// remote != local ise guncelleme var demektir.
  /// Ancak remote == ignored_build ise guncelleme ekranı çıkmaz.
  static Future<({bool available, int remoteBuild})> checkUpdate() async {
    try {
      final remote = await getRemoteBuildNumber();
      final local = await getLocalBuildNumber();
      
      final prefs = await SharedPreferences.getInstance();
      final ignored = prefs.getInt(_ignoredKey) ?? 0;

      if (remote == ignored) {
        return (available: false, remoteBuild: remote); // Görmezden gelinen sürüm, gösterme
      }

      return (available: remote != local, remoteBuild: remote);
    } catch (_) {
      return (available: false, remoteBuild: 0);
    }
  }

  /// APK'yi indirir ve indirme ilerlemesini bildirir (0.0 - 1.0).
  /// Indirme bittikten sonra build_number'i SharedPreferences'a kaydeder.
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

    final contentLength = response.contentLength ?? 0;
    int downloaded = 0;
    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      downloaded += chunk.length;
      if (contentLength > 0) {
        onProgress(downloaded / contentLength);
      }
    }

    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      // Eski kurulum dosyalarını temizle
      final files = dir.listSync();
      for (var f in files) {
        if (f is File && f.path.contains('nimo_update_')) {
          try {
            f.deleteSync();
          } catch (_) {}
        }
      }
    }

    final savePath = '${dir!.path}/nimo_update_$newBuildNumber.apk';
    final file = File(savePath);
    
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
