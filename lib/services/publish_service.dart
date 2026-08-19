import 'dart:convert';

import 'package:flutter/foundation.dart';

/// MQTT / backend entegrasyonu için tek giriş noktası.
///
/// Şu an yalnızca gönderilecek yükü hazırlayıp konsola yazar.
/// MQTT eklenince [publish] gövdesi `MqttServerClient.publishMessage(...)`
/// çağrısıyla değiştirilecek; ekranlarda başka değişiklik gerekmeyecek.
class PublishService {
  PublishService._();

  static final PublishService instance = PublishService._();

  static const String baseTopic = 'nimo/bakim';

  /// Servis Raporu ekranının yükü.
  ///
  /// [items] rapora eklenen satırlardır: lastik raporunda her lastiğin seri no
  /// ve tarihleri, yağ raporunda her takviye türünün tarihleri. Arıza
  /// raporunda boş gelir.
  Future<PublishResult> publishReport({
    required String reportType,
    required String description,
    required List<String> imagePaths,
    List<Map<String, Object?>> items = const <Map<String, Object?>>[],
    String? vehicleCode,
    String? userRegistryNo,
  }) async {
    final Map<String, Object?> payload = <String, Object?>{
      'reportType': reportType,
      'description': description,
      'vehicle': vehicleCode,
      'user': userRegistryNo,
      'imageCount': imagePaths.length,
      'images': imagePaths,
      'itemCount': items.length,
      'items': items,
      'sentAt': DateTime.now().toIso8601String(),
    };
    return publish('$baseTopic/rapor', payload);
  }

  /// Lastik / Yağ ekranındaki "Gönder" butonunun yükü: o ekranda yapılıp
  /// henüz gönderilmemiş işlemler tek mesajda toplanır.
  Future<PublishResult> publishOperations({
    required String topic,
    required String group,
    required List<Map<String, Object?>> operations,
    String? vehicleCode,
    String? userRegistryNo,
  }) async {
    final Map<String, Object?> payload = <String, Object?>{
      'group': group,
      'vehicle': vehicleCode,
      'user': userRegistryNo,
      'operationCount': operations.length,
      'operations': operations,
      'sentAt': DateTime.now().toIso8601String(),
    };
    return publish(topic, payload);
  }

  Future<PublishResult> publish(String topic, Map<String, Object?> payload) async {
    final String json = jsonEncode(payload);
    // TODO(mqtt): gerçek broker bağlantısı eklenecek.
    debugPrint('[MQTT] $topic -> $json');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return PublishResult(topic: topic, payload: json, success: true);
  }
}

@immutable
class PublishResult {
  const PublishResult({
    required this.topic,
    required this.payload,
    required this.success,
    this.error,
  });

  final String topic;
  final String payload;
  final bool success;
  final String? error;
}
