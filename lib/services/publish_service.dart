import 'package:flutter/foundation.dart';
import 'fleet_event_client.dart';
import 'fleet_event_mapper.dart';

class PublishService {
  PublishService._();

  static final PublishService instance = PublishService._();
  final FleetEventClient _client = HttpFleetEventClient();

  static const String baseTopic = 'nimo/bakim';

  Future<PublishResult> publishReport({
    required String reportType,
    required String description,
    required List<String> imagePaths,
    List<Map<String, Object?>> items = const <Map<String, Object?>>[],
    String? vehicleCode,
    String? userRegistryNo,
    String? startTime,
    String? endTime,
  }) async {
    final FleetEvent event = FleetEventMapper.fromReport(
      reportType: reportType,
      description: description,
      imageCount: imagePaths.length,
      imageNames: imagePaths,
      deviceId: null,
      vehicleLabel: vehicleCode,
      operatorLabel: userRegistryNo,
      occurredAt: DateTime.now(),
      startTime: startTime,
      endTime: endTime,
    );

    final FleetResult result = await _client.send(event);
    return PublishResult(
      topic: baseTopic,
      payload: event.toJson().toString(),
      success: result.ok,
      error: result.error,
    );
  }

  Future<PublishResult> publishOperations({
    required String topic,
    required String group,
    required List<Map<String, Object?>> operations,
    String? vehicleCode,
    String? userRegistryNo,
  }) async {
    // operations listesi PendingOperation'in payload'ı gibi.
    // Her işlem için ayrı event oluşturmamız gerekir, ancak publishOperations tek sonuç bekliyor.
    // Bu yüzden tümünü toplu bir olay olarak gönderelim.
    final FleetEvent event = FleetEvent(
      title: group,
      type: 'İŞLEM',
      note: 'Toplu İşlem (${operations.length} adet)',
      vehicleLabel: vehicleCode,
      operatorLabel: userRegistryNo,
      occurredAt: DateTime.now(),
      fields: <String, Object?>{
        'islem': group,
        'operationCount': operations.length,
      },
    );

    final FleetResult result = await _client.send(event);
    return PublishResult(
      topic: topic,
      payload: event.toJson().toString(),
      success: result.ok,
      error: result.error,
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
