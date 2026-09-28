import '../models/models.dart';
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
    required UserProfile? user,
    required String? vehicleUUID,
  }) {
    final Map<String, Object?> payload = operation.payload;
    final String op = '${payload['op'] ?? ''}';

    return FleetEvent(
      title: _titleFor(operation.kind),
      // Yağ ekranında hangi bölümde çalışıldığı ("Manuel Yağlamalar" /
      // "Yağ Takviyeleri"); lastik işlemlerinde boştur ve gönderilmez.
      subtitle: '${payload['category'] ?? ''}',
      type: _typeFor(operation.kind),
      deviceId: deviceId,
      vehicleUUID: vehicleUUID,
      operatorLabel: operatorLabel(user),
      occurredAt: operation.date,
      // `op` başlıkta ve türde zaten temsil ediliyor; alan olarak da gönderilir
      // ki panelde filtrelenebilsin. `category` başlığın altında `subtitle`
      // olarak gittiği için alanlara tekrar yazılmaz. Operatörün adı ve sicili
      // ayrıca alan olarak gider; `operatorLabel` yalnızca okunabilir metin.
      fields: <String, Object?>{
        'islem': op,
        if (user != null && user.fullName.trim().isNotEmpty)
          'operatorAdi': user.fullName.trim(),
        if (user != null && user.registryNo.trim().isNotEmpty)
          'sicilNo': user.registryNo.trim(),
        for (final MapEntry<String, Object?> e in payload.entries)
          if (e.key != 'op' && e.key != 'category') _fieldName(e.key): e.value,
      },
    );
  }

  /// Panelde gösterilen operatör metni: `Ahmet Yılmaz (12345)`.
  /// Ad ya da sicil eksikse var olan tek bilgi gönderilir.
  static String? operatorLabel(UserProfile? user) {
    if (user == null) return null;
    final String name = user.fullName.trim();
    final String registryNo = user.registryNo.trim();
    if (name.isEmpty) return registryNo.isEmpty ? null : registryNo;
    return registryNo.isEmpty ? name : '$name ($registryNo)';
  }

  /// Servis Raporu / Mekanik Operasyon ekranından gönderilen rapor.
  static FleetEvent fromReport({
    required String reportType,
    required String? service,
    required String description,
    required int imageCount,
    required List<String> imageNames,
    required String? deviceId,
    required String? vehicleUUID,
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
      vehicleUUID: vehicleUUID,
      operatorLabel: operatorLabel,
      service: service,
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
    'Servis Raporu': 'bakım',
    'Mekanik Operasyon': 'bakim',
  };

  /// Yağ işlemleri `bakim` sayılır; `yakit` yakıt ikmalini çağrıştırdığı için
  /// kullanılmaz.
  static String _typeFor(PendingKind kind) => switch (kind) {
        PendingKind.tire => 'lastik',
        PendingKind.oil => 'bakim',
      };

  /// Başlık işlemin yapıldığı ekranı söyler; ne yapıldığını `islem`, yağ
  /// ekranındaki bölüm ayrımını `subtitle` taşır. `kontrol` her iki ekranda da
  /// kullanıldığı için başlık işlem koduna göre değil ekrana göre seçilir.
  static String _titleFor(PendingKind kind) => switch (kind) {
        PendingKind.tire => 'Lastik Değişimi',
        PendingKind.oil => 'Yağ Takviyesi',
      };

  /// Panelde okunabilir alan adları.
  static String _fieldName(String key) => switch (key) {
        'tireId' => 'lastikId',
        'position' => 'konum',
        'serialNo' => 'seriNo',
        'previousSerialNo' => 'oncekiSeriNo',
        'items' => 'kontroller',
        'airCompleted' => 'havaTamamlandi',
        'repairDone' => 'tamiratYapildi',
        'note' => 'not',
        'oilType' => 'yagTuru',
        'amount' => 'miktarLitre',
        'product' => 'urun',
        _ => key,
      };
}
