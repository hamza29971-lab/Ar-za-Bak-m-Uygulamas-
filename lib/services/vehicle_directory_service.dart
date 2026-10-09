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
    // Sunucu UUID'yi `value`, adı `label` alanında döndürüyor.
    final String id = _firstNonEmpty(json, const <String>[
      'value',
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
  static const int _pageSize = 100;

  /// Sunucu sayfa numarasını yok sayıp hep aynı sayfayı dönerse sonsuz
  /// döngüye girmemek için üst sınır.
  static const int _maxPages = 50;

  /// Tüm sayfaları çeker. Herhangi bir sayfa başarısız olursa boş liste
  /// döner: yarım liste, eksik araçları yanlışlıkla "kayıp" gösterirdi.
  Future<List<VehicleDirectoryEntry>> fetchAll({required String? accessToken}) async {
    final Map<String, VehicleDirectoryEntry> byId = <String, VehicleDirectoryEntry>{};
    try {
      for (int page = 0; page < _maxPages; page++) {
        final List<Object?>? rawList = await _fetchPage(page, accessToken);
        if (rawList == null) return const <VehicleDirectoryEntry>[];

        int fresh = 0;
        for (final Object? item in rawList) {
          if (item is Map<String, Object?>) {
            final VehicleDirectoryEntry? entry = VehicleDirectoryEntry.fromJson(item);
            if (entry != null && byId.putIfAbsent(entry.id, () => entry) == entry) {
              fresh++;
            }
          }
        }
        if (rawList.length < _pageSize || fresh == 0) break;
      }
      return byId.values.toList();
    } on Object catch (e) {
      debugPrint('[VehicleDirectory] gönderim hatası: $e');
      return const <VehicleDirectoryEntry>[];
    }
  }

  /// Tek sayfa; HTTP hatasında `null`.
  Future<List<Object?>?> _fetchPage(int page, String? accessToken) async {
    final http.Response response = await _client
        .post(
          Uri.parse('${AuthApiService.baseUrl}$_path'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            if (accessToken != null && accessToken.isNotEmpty)
              'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(<String, Object?>{
            'filters': const <Object?>[],
            'pageNumber': page,
            'pageSize': _pageSize,
            'sortType': 'ASC',
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        '[VehicleDirectory] HTTP ${response.statusCode} (sayfa $page): ${response.body}',
      );
      return null;
    }

    final Object? decoded = jsonDecode(utf8.decode(response.bodyBytes));
    // Keşif amaçlı: gerçek alan adları doğrulanana kadar ham cevabı loglar.
    debugPrint('[VehicleDirectory] ham cevap (sayfa $page): $decoded');
    return _extractList(decoded);
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
