import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Fleet Panel'e gönderilen bir saha kaydı.
///
/// Alanlar `docs/fleet-entegrasyon-plani.md` ve entegrasyon dokümanındaki
/// sözleşmeyle birebir aynıdır. Sunucu her istek için **yeni bir kayıt** açar;
/// aynı olay iki kez gönderilirse panelde iki satır görünür.
@immutable
class FleetEvent {
  const FleetEvent({
    required this.title,
    this.subtitle = '',
    this.type = 'genel',
    this.note = '',
    this.deviceId,
    this.vehicleUUID,
    this.operatorLabel,
    this.occurredAt,
    this.fields = const <String, Object?>{},
  });

  /// Zorunlu. Sunucu 2–200 karakter bekler.
  final String title;

  /// Başlığın hemen altındaki ikincil satır, ör. "Manuel Yağlamalar".
  /// Boşsa hiç gönderilmez.
  final String subtitle;

  /// `bakim`, `lastik`, `yakit`, `ariza`, `genel`.
  final String type;

  /// En fazla 2000 karakter.
  final String note;

  final String? deviceId;
  final String? vehicleUUID;
  final String? operatorLabel;
  final DateTime? occurredAt;

  /// Ek anahtar/değer. Sunucu yalnızca string, number ve boolean kabul eder;
  /// en fazla 20 anahtar alır. [toJson] bu kuralları uygular.
  final Map<String, Object?> fields;

  static const int maxTitle = 200;
  static const int maxNote = 2000;
  static const int maxFields = 20;

  /// Sunucunun beklediği gövde. Boş alanlar hiç gönderilmez.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': _clamp(title, maxTitle),
      if (subtitle.trim().isNotEmpty)
        'subtitle': _clamp(subtitle.trim(), maxTitle),
      'type': type,
      if (note.trim().isNotEmpty) 'note': _clamp(note.trim(), maxNote),
      if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
      if (vehicleUUID != null && vehicleUUID!.isNotEmpty)
        'vehicleUUID': vehicleUUID,
      'operatorLabel': (operatorLabel != null && operatorLabel!.trim().isNotEmpty) ? operatorLabel : '-',
      // Yerel saatin ISO çıktısında dilim eki olmadığı için UTC gönderilir.
      if (occurredAt != null)
        'occurredAt': occurredAt!.toUtc().toIso8601String(),
      'source': AppConfig.fleetSource,
      if (fields.isNotEmpty) 'fields': _sanitizeFields(fields),
    };
  }

  static String _clamp(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  /// Sunucu `fields` içinde yalnızca string / number / boolean kabul eder.
  /// Liste ve haritalar metne çevrilir, boş değerler atılır, 20 anahtarla
  /// sınırlanır.
  static Map<String, Object?> _sanitizeFields(Map<String, Object?> raw) {
    final Map<String, Object?> out = <String, Object?>{};
    for (final MapEntry<String, Object?> e in raw.entries) {
      if (out.length >= maxFields) break;
      final Object? v = e.value;
      if (v == null) continue;
      if (v is num || v is bool) {
        out[e.key] = v;
      } else if (v is Iterable<Object?>) {
        if (e.key == 'gorseller') {
          // Base64 görselleri kırpmadan listeye çevirip ekle
          out[e.key] = v.toList();
        } else {
          final String joined = v.map((Object? x) => '$x').join(', ');
          if (joined.isNotEmpty) out[e.key] = _clamp(joined, maxNote);
        }
      } else {
        final String text = '$v'.trim();
        if (text.isNotEmpty) out[e.key] = _clamp(text, maxNote);
      }
    }
    return out;
  }
}

/// Tek bir gönderimin sonucu.
@immutable
class FleetResult {
  const FleetResult.success(this.id)
      : ok = true,
        error = null;

  const FleetResult.failure(this.error)
      : ok = false,
        id = null;

  final bool ok;

  /// Sunucunun verdiği kayıt kimliği (başarılıysa).
  final String? id;

  /// Kullanıcıya gösterilebilecek Türkçe hata metni.
  final String? error;
}

/// Fleet Panel istemcisi. Ekranlar yalnızca bu arayüzü tanır; testlerde
/// [MockFleetEventClient] yerleştirilir.
abstract interface class FleetEventClient {
  Future<FleetResult> send(FleetEvent event, {String? accessToken});

  /// Bağlantı sınaması; anahtar gerektirmez.
  Future<bool> health();
}

/// Gerçek uç noktaya POST eden istemci.
class HttpFleetEventClient implements FleetEventClient {
  HttpFleetEventClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<FleetResult> send(FleetEvent event, {String? accessToken}) async {
    final String payload = jsonEncode(event.toJson());
    debugPrint('[Fleet] gönderim: $payload');
    try {
      final http.Response response = await _client
          .post(
            Uri.parse(AppConfig.fleetEventUrl),
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (accessToken != null && accessToken.isNotEmpty)
                'Authorization': 'Bearer $accessToken',
            },
            body: payload,
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Object? body = jsonDecode(utf8.decode(response.bodyBytes));
        // Yeni API: data.uuid; eski Fleet API: id
        String? id;
        if (body is Map<String, Object?>) {
          final Object? data = body['data'];
          if (data is Map<String, Object?>) {
            id = data['uuid'] as String?;
          }
          id ??= body['id'] as String?;
        }
        debugPrint('[Fleet] gönderim başarılı, kayıt id: $id');
        return FleetResult.success(id);
      }
      debugPrint('[Fleet] gönderim reddedildi: HTTP ${response.statusCode} ${response.body}');
      return FleetResult.failure(
        messageFor(response.statusCode, utf8.decode(response.bodyBytes)),
      );
    } on Object catch (e) {
      debugPrint('[Fleet] gönderim hatası: $e');
      return const FleetResult.failure(
        'Bağlantı kurulamadı. İnternet bağlantınızı kontrol edin.',
      );
    }
  }

  @override
  Future<bool> health() async {
    try {
      final http.Response response = await _client
          .get(Uri.parse(AppConfig.fleetHealthUrl))
          .timeout(AppConfig.requestTimeout);
      return response.statusCode == 200;
    } on Object {
      return false;
    }
  }

  /// Sunucu cevabının kullanıcıya gösterilecek Türkçe karşılığı.
  ///
  /// mining-be 401'i iki farklı durumda döndürüyor: token hiç yoksa JSON
  /// `{"code":"UNAUTHORIZED"}`, token geçerli ama yetki yoksa düz metin
  /// "You do not have permission...". Süresi dolmuş/geçersiz token ise 440.
  @visibleForTesting
  static String messageFor(int status, String body) {
    String? code;
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) code = decoded['code'] as String?;
    } on FormatException {
      // Düz metin gövde (izin reddi); kod yok.
    }

    return switch (status) {
      400 => 'Kayıt eksik veya hatalı; gönderilemedi.',
      401 when code == 'UNAUTHORIZED' =>
        'Oturum bilgisi gönderilemedi. Lütfen çıkış yapıp tekrar giriş yapın.',
      401 => 'Sunucu bu hesaba işlem kaydetme yetkisi vermiyor. '
          'Yöneticinize bildirin.',
      440 => 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      405 => 'Sunucu bu isteği kabul etmedi.',
      503 => 'Sunucu şu an hizmet veremiyor. Daha sonra deneyin.',
      _ => 'Sunucu kaydı alamadı (HTTP $status).',
    };
  }
}

/// Ağa çıkmayan istemci: testler ve çevrimdışı geliştirme için.
class MockFleetEventClient implements FleetEventClient {
  MockFleetEventClient({this.failWith, this.healthy = true});

  /// Doluysa her gönderim bu hatayla başarısız olur.
  final String? failWith;
  final bool healthy;

  /// Gönderilen olaylar; testler burayı okur.
  final List<FleetEvent> sent = <FleetEvent>[];

  int _counter = 0;

  @override
  Future<FleetResult> send(FleetEvent event, {String? accessToken}) async {
    sent.add(event);
    if (failWith != null) return FleetResult.failure(failWith);
    debugPrint('[Fleet] ${jsonEncode(event.toJson())}');
    return FleetResult.success('mock-${++_counter}');
  }

  @override
  Future<bool> health() async => healthy;
}
