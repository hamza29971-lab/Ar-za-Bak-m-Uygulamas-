import '../state/app_state.dart';
import 'fleet_event_client.dart';

/// Uygulamadaki işlemleri Fleet Panel olayına çevirir.
///
/// Panelde okunabilir bir başlık üretmek ve `fields` içine yalnızca sunucunun
/// kabul ettiği türleri koymak bu sınıfın işidir.
class FleetEventMapper {
  FleetEventMapper._();

  /// Lastik / yağ ekranlarındaki bekleyen bir işlem.
  static FleetEvent fromPending(
    PendingOperation operation, {
    required String? deviceId,
    required String? operatorLabel,
  }) {
    final Map<String, Object?> payload = operation.payload;
    final String op = '${payload['op'] ?? ''}';

    return FleetEvent(
      title: _titleFor(op, payload),
      type: _typeFor(op),
      deviceId: deviceId,
      vehicleLabel: operation.vehicleCode,
      operatorLabel: operatorLabel,
      occurredAt: operation.date,
      // `op` anahtarı başlık ve türde zaten temsil ediliyor; alan olarak da
      // gönderilir ki panelde filtrelenebilsin.
      fields: <String, Object?>{
        'islem': op,
        for (final MapEntry<String, Object?> e in payload.entries)
          if (e.key != 'op') _fieldName(e.key): e.value,
      },
    );
  }

  /// Servis Raporu / Mekanik Operasyon ekranından gönderilen rapor.
  static FleetEvent fromReport({
    required String reportType,
    required String description,
    required int imageCount,
    required List<String> imageNames,
    required String? deviceId,
    required String? vehicleLabel,
    required String? operatorLabel,
    required DateTime occurredAt,
    String? startTime,
    String? endTime,
  }) {
    return FleetEvent(
      title: reportType,
      type: _reportTypes[reportType] ?? 'genel',
      note: description,
      deviceId: deviceId,
      vehicleLabel: vehicleLabel,
      operatorLabel: operatorLabel,
      occurredAt: occurredAt,
      fields: <String, Object?>{
        'raporTuru': reportType,
        'gorselSayisi': imageCount,
        // Uç nokta dosya yüklemiyor; yalnızca hangi dosyaların eklendiği
        // bilgisi taşınabiliyor (bkz. docs/fleet-entegrasyon-plani.md).
        if (imageNames.isNotEmpty) 'gorseller': imageNames,
        // Servis raporunda kullanıcı servisin başlangıç/bitiş saatini seçer.
        'baslangicSaati': ?startTime,
        'bitisSaati': ?endTime,
      },
    );
  }

  // ------------------------------------------------------------------ eşleme

  static const Map<String, String> _reportTypes = <String, String>{
    'Servis Formu': 'genel',
    'Arıza Raporu': 'ariza',
    'Mekanik Operasyon': 'bakim',
  };

  /// Yağ işlemleri `bakim` sayılır; `yakit` yakıt ikmalini çağrıştırdığı için
  /// kullanılmaz.
  static String _typeFor(String op) =>
      op.startsWith('lastik') ? 'lastik' : 'bakim';

  static String _titleFor(String op, Map<String, Object?> payload) {
    final String tire = '${payload['tireId'] ?? ''}';
    final String position = '${payload['position'] ?? ''}';
    final String oilType = '${payload['oilType'] ?? ''}';
    final String areaId = '${payload['areaId'] ?? ''}';

    final String tireLabel =
        position.isEmpty ? tire : '$tire ($position)'.trim();
    final String oilLabel = areaId.isEmpty ? oilType : '$oilType ($areaId)';

    return switch (op) {
      'lastik_degisim' => 'Lastik değişimi — $tireLabel',
      'lastik_kontrol' => 'Lastik kontrolü — $tireLabel',
      'yag_takviye' => 'Yağ takviyesi — $oilLabel',
      'yag_kontrol' => 'Yağ kontrolü — $oilLabel',
      _ => 'Saha işlemi',
    };
  }

  /// Panelde okunabilir alan adları.
  static String _fieldName(String key) => switch (key) {
        'tireId' => 'lastikId',
        'position' => 'konum',
        'serialNo' => 'seriNo',
        'items' => 'kontroller',
        'note' => 'not',
        'areaId' => 'alanId',
        'oilType' => 'yagTuru',
        'amount' => 'miktarLitre',
        'product' => 'urun',
        _ => key,
      };
}
