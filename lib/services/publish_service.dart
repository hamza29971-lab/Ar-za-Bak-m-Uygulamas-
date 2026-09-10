import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../state/app_state.dart' show AppState, PendingOperation;
import 'fleet_event_client.dart';
import 'fleet_event_mapper.dart';
import 'service_locator.dart';

class PublishService {
  PublishService._();

  static final PublishService instance = PublishService._();
  final FleetEventClient _client = HttpFleetEventClient();

  static const String baseTopic = 'nimo/bakim';

  /// Araç sunucudaki listeyle eşleşmediğinde kayıt hiç gönderilmez; aksi
  /// halde panelde hangi araca ait olduğu belli olmayan bir satır oluşurdu.
  static String _missingUuidError(String? vehicleCode) =>
      '${vehicleCode ?? 'Araç'} sunucudaki araç listesinde bulunamadı. '
      'Kayıt gönderilmedi; yöneticinize bildirin.';

  Future<PublishResult> publishReport({
    required AppState state,
    required String reportType,
    required String description,
    required List<String> imagePaths,
    List<Map<String, Object?>> items = const <Map<String, Object?>>[],
    String? vehicleCode,
    String? userRegistryNo,
    String? startTime,
    String? endTime,
  }) async {
    // 1. Resimleri Base64 formatına çevir (eğer resim varsa)
    List<String> base64Images = [];
    if (imagePaths.isNotEmpty) {
      for (String path in imagePaths) {
        try {
          final bytes = File(path).readAsBytesSync();
          final base64String = base64Encode(bytes);
          base64Images.add('data:image/jpeg;base64,$base64String');
        } catch (e) {
          debugPrint('Base64 dönüştürme hatası: $e');
        }
      }
    }

    final String? vehicleUUID = state.vehicleUuidFor(vehicleCode);
    if (vehicleUUID == null) {
      return PublishResult(
        topic: baseTopic,
        payload: '',
        success: false,
        error: _missingUuidError(vehicleCode),
      );
    }

    final FleetEvent event = FleetEventMapper.fromReport(
      reportType: reportType,
      description: description,
      imageCount: base64Images.length,
      imageNames: base64Images, // Base64 verilerini API'ye gönder
      deviceId: null,
      vehicleUUID: vehicleUUID,
      operatorLabel: userRegistryNo,
      occurredAt: DateTime.now(),
      startTime: startTime,
      endTime: endTime,
    );

    // 2. Access token'ı güvenli deposundan oku
    final String? accessToken = await ServiceLocator.tokens.readAccessToken();

    final FleetResult result = await _client.send(event, accessToken: accessToken);
    return PublishResult(
      topic: baseTopic,
      payload: event.toJson().toString(),
      success: result.ok,
      error: result.error,
    );
  }

  /// Kuyruktaki her bekleyen işlemi kendi detaylarıyla (lastik/seri no veya
  /// yağ bölgesi/miktar/ürün) tek tek sunucuya gönderir; tek bir özet olay
  /// yerine sunucuda her işlem için ayrı bir kayıt açılır.
  ///
  /// İlk hatada durur: o ana kadar gönderilenler sunucuya ulaşmış olur,
  /// ancak ekran yalnızca tamamı başarılı olursa kuyruğu temizler — böylece
  /// kullanıcı "Gönder"e tekrar basarak kalanları yeniden dener.
  Future<PublishResult> publishOperations({
    required AppState state,
    required String topic,
    required List<PendingOperation> pending,
    UserProfile? user,
  }) async {
    // Kuyrukta UUID'si çözülemeyen bir araç varsa hiçbir şey gönderilmez:
    // yarısı gitmiş bir kuyruğu kullanıcının elle ayıklaması gerekirdi.
    for (final PendingOperation operation in pending) {
      if (state.vehicleUuidFor(operation.vehicleCode) == null) {
        return PublishResult(
          topic: topic,
          payload: '',
          success: false,
          error: _missingUuidError(operation.vehicleCode),
        );
      }
    }

    int sent = 0;
    for (final PendingOperation operation in pending) {
      final FleetEvent event = FleetEventMapper.fromPending(
        operation,
        deviceId: null,
        user: user,
        vehicleUUID: state.vehicleUuidFor(operation.vehicleCode),
      );
      final String? accessToken = await ServiceLocator.tokens.readAccessToken();
      final FleetResult result = await _client.send(event, accessToken: accessToken);
      if (!result.ok) {
        return PublishResult(
          topic: topic,
          payload: '$sent/${pending.length} işlem gönderildi',
          success: false,
          error: result.error,
        );
      }
      sent++;
    }
    return PublishResult(
      topic: topic,
      payload: '$sent işlem ayrı ayrı gönderildi',
      success: true,
    );
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
