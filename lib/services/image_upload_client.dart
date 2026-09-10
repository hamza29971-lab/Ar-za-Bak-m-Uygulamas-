import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';

/// Tek bir görsel yüklemesinin sonucu.
@immutable
class UploadResult {
  const UploadResult.success(this.url)
      : ok = true,
        error = null;

  const UploadResult.failure(this.error)
      : ok = false,
        url = null;

  final bool ok;

  /// Sunucunun döndürdüğü, herkesin erişebileceği görsel adresi.
  final String? url;

  /// Kullanıcıya gösterilebilecek Türkçe hata metni.
  final String? error;
}

/// Görselleri Fleet Panel'e yükleyen istemci. Ekranlar yalnızca bu arayüzü
/// tanır; testlerde [MockImageUploadClient] yerleştirilir.
abstract interface class ImageUploadClient {
  /// [filePath] cihazdaki dosya yolu. Başarılıysa erişilebilir URL döner.
  Future<UploadResult> upload(String filePath);
}

/// Gerçek uç noktaya `multipart/form-data` gönderen istemci.
///
/// Dosya belleğe tamamen alınmaz; [http.MultipartFile.fromPath] içeriği
/// akış olarak aktarır. Rapor gövdesi bu sayede küçük bir JSON olarak kalır.
class HttpImageUploadClient implements ImageUploadClient {
  HttpImageUploadClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<UploadResult> upload(String filePath) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.fleetUploadUrl),
      )
        ..headers['X-Fleet-Key'] = AppConfig.fleetApiKey
        ..fields['source'] = AppConfig.fleetSource
        ..files.add(await http.MultipartFile.fromPath(
          AppConfig.fleetUploadField,
          filePath,
          contentType: _mediaTypeFor(filePath),
        ));

      // request.send() kendi tek kullanımlık istemcisini açar; enjekte edilen
      // istemciyi kullanmak bağlantıyı paylaşır ve testlerde sahte istemcinin
      // devreye girmesini sağlar.
      final http.StreamedResponse streamed =
          await _client.send(request).timeout(AppConfig.uploadTimeout);
      final http.Response response =
          await http.Response.fromStream(streamed);

      if (response.statusCode != 200 && response.statusCode != 201) {
        return UploadResult.failure(_messageFor(response.statusCode));
      }

      final String? url = _urlFrom(response.bodyBytes);
      if (url == null) {
        debugPrint('[Upload] beklenmeyen yanıt: ${response.body}');
        return const UploadResult.failure(
          'Sunucu görsel adresini döndürmedi.',
        );
      }
      return UploadResult.success(url);
    } on Object catch (e) {
      debugPrint('[Upload] hata: $e');
      return const UploadResult.failure(
        'Görsel yüklenemedi. İnternet bağlantınızı kontrol edin.',
      );
    }
  }

  /// Yanıt gövdesinden adresi çıkarır.
  ///
  /// Sunucu sözleşmesi netleşene kadar yaygın anahtar adlarının hepsi
  /// denenir; böylece küçük bir isim farkı gönderimi bozmaz.
  static String? _urlFrom(List<int> bodyBytes) {
    final Object? body = jsonDecode(utf8.decode(bodyBytes));
    if (body is! Map<String, Object?>) return null;
    for (final String key in <String>['url', 'location', 'path', 'src']) {
      final Object? value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    // Bazı uçlar yalnızca kimlik döndürür; adres onun üzerine kurulur.
    final Object? id = body['id'];
    if (id != null && '$id'.trim().isNotEmpty) {
      return '${AppConfig.fleetUploadUrl}/${'$id'.trim()}';
    }
    return null;
  }

  static MediaType _mediaTypeFor(String path) {
    final String ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'heic' || 'heif' => MediaType('image', 'heic'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  static String _messageFor(int status) => switch (status) {
        400 => 'Görsel kabul edilmedi; dosya bozuk olabilir.',
        401 => 'Sunucu anahtarı geçersiz. Yöneticinize bildirin.',
        413 => 'Görsel çok büyük; sunucu kabul etmedi.',
        415 => 'Görsel biçimi desteklenmiyor.',
        503 => 'Sunucu şu an hizmet veremiyor. Daha sonra deneyin.',
        _ => 'Görsel yüklenemedi (HTTP $status).',
      };
}

/// Ağa çıkmayan istemci: testler ve çevrimdışı geliştirme için.
class MockImageUploadClient implements ImageUploadClient {
  MockImageUploadClient({this.failWith});

  /// Doluysa her yükleme bu hatayla başarısız olur.
  final String? failWith;

  /// Yüklenen dosya yolları; testler burayı okur.
  final List<String> uploaded = <String>[];

  int _counter = 0;

  @override
  Future<UploadResult> upload(String filePath) async {
    uploaded.add(filePath);
    if (failWith != null) return UploadResult.failure(failWith);
    return UploadResult.success(
      'https://ornek.test/uploads/${++_counter}.jpg',
    );
  }
}
