import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_api_service.dart';

/// mining-be'deki `search-auto-complete` sonucunda dönen tek bir araç kaydı.
///
/// Sunucunun gerçek alan adları henüz doğrulanmadığı için birden fazla
/// olası anahtar denenir; ilk dolu olan kullanılır.
@immutable
class VehicleDirectoryEntry {
  const VehicleDirectoryEntry({required this.id, required this.label});

  final String id;
  final String label;

  static VehicleDirectoryEntry? fromJson(Map<String, Object?> json) {
    final String id = _firstNonEmpty(json, const <String>[
      'id',
      'uuid',
      'vehicleId',
      'vehicleUuid',
    ]);
    final String label = _firstNonEmpty(json, const <String>[
      'name',
      'label',
      'code',
      'plate',
      'vehicleLabel',
      'vehicleName',
    ]);
    if (id.isEmpty || label.isEmpty) return null;
    return VehicleDirectoryEntry(id: id, label: label);
  }

  static String _firstNonEmpty(Map<String, Object?> json, List<String> keys) {
    for (final String key in keys) {
      final Object? value = json[key];
      if (value != null && '$value'.trim().isNotEmpty) return '$value'.trim();
    }
    return '';
  }
}

/// mining-be'deki araç dizinini çeken istemci.
class VehicleDirectoryService {
  VehicleDirectoryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _path = '/devices/vehicles/search-auto-complete';

  Future<List<VehicleDirectoryEntry>> fetchAll({required String? accessToken}) async {
    try {
      final http.Response response = await _client
          .post(
            Uri.parse('${AuthApiService.baseUrl}$_path'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (accessToken != null && accessToken.isNotEmpty)
                'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(const <String, Object?>{
              'filters': <Object?>[],
              'pageNumber': 0,
              'pageSize': 100,
              'sortType': 'ASC',
            }),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[VehicleDirectory] HTTP ${response.statusCode}: ${response.body}',
        );
        return const <VehicleDirectoryEntry>[];
      }

      final Object? decoded = jsonDecode(utf8.decode(response.bodyBytes));
      // Keşif amaçlı: gerçek alan adları doğrulanana kadar ham cevabı loglar.
      debugPrint('[VehicleDirectory] ham cevap: $decoded');

      final List<Object?> rawList = _extractList(decoded);
      final List<VehicleDirectoryEntry> entries = <VehicleDirectoryEntry>[];
      for (final Object? item in rawList) {
        if (item is Map<String, Object?>) {
          final VehicleDirectoryEntry? entry = VehicleDirectoryEntry.fromJson(item);
          if (entry != null) entries.add(entry);
        }
      }
      return entries;
    } on Object catch (e) {
      debugPrint('[VehicleDirectory] gönderim hatası: $e');
      return const <VehicleDirectoryEntry>[];
    }
  }

  /// Sunucu listeyi doğrudan, `data` altında ya da `data.content` altında
  /// döndürmüş olabilir; ilk bulunan liste kullanılır.
  static List<Object?> _extractList(Object? decoded) {
    if (decoded is List<Object?>) return decoded;
    if (decoded is Map<String, Object?>) {
      for (final String key in const <String>['content', 'items', 'list', 'data']) {
        final Object? value = decoded[key];
        if (value is List<Object?>) return value;
        if (value is Map<String, Object?>) {
          final List<Object?> nested = _extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return const <Object?>[];
  }
}
