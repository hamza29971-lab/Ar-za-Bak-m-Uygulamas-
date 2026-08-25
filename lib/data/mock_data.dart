import '../models/models.dart';
import 'fleet.dart';

/// Backend bağlanana kadar arayüzü beslemek için örnek veriler.
/// MQTT / servis entegrasyonunda bu katmanın yerine repository gelecek.
class MockData {
  MockData._();

  static const UserProfile user = UserProfile(
    fullName: 'ŞAHİN KAYA',
    email: 'sahinkaya@hotmail.com',
    phone: '(0532) 555 40 62',
    role: 'ŞOFÖR',
    registryNo: '95674DBC93',
    machineCode: 'Euclid-2',
    machineType: 'ROCK_TRUCK',
  );

  /// Filo tanımları `lib/data/fleet.dart` içinde tutulur.
  static List<Vehicle> vehicles() => Fleet.vehicles();

  /// Seçilen aracın lastik konumlarına göre kayıt üretir.
  static List<TireRecord> tiresFor(Vehicle vehicle) {
    final int seed = vehicle.code.hashCode.abs();
    final DateTime now = DateTime.now();
    return List<TireRecord>.generate(vehicle.tirePositions.length, (int i) {
      final int changeOffset = 40 + (seed + i * 37) % 260;
      final int checkOffset = 1 + (seed + i * 13) % 30;
      final String no = (i + 1).toString().padLeft(2, '0');
      return TireRecord(
        tireId: '${vehicle.code}-L$no',
        serialNo: 'SN${(seed % 90000 + 10000 + i * 7)}',
        position: vehicle.tirePositions[i],
        lastChangeDate: null,
        lastCheckDate: null,
      );
    });
  }

  /// Seçilen aracın yağ alanlarına göre kayıt üretir.
  static List<OilRecord> oilsFor(Vehicle vehicle) {
    final int seed = vehicle.code.hashCode.abs();
    final DateTime now = DateTime.now();
    return List<OilRecord>.generate(vehicle.oilAreas.length, (int i) {
      final OilArea area = vehicle.oilAreas[i];
      final int offset = 5 + (seed + i * 23) % 120;
      final int checkOffset = 1 + (seed + i * 17) % 30;
      return OilRecord(
        areaId: area.id,
        oilType: area.name,
        category: area.category,
        amount: 2 + ((seed + i * 11) % 18).toDouble(),
        lastOilDate: null,
        lastCheckDate: null,
      );
    });
  }

  /// Anasayfadaki "Son İşlemler" listesi için başlangıç geçmişi.
  /// Gerçek servis geldiğinde bu kayıtlar backend'den gelecek.
  static List<ActivityRecord> activities(List<Vehicle> vehicles) {
    return <ActivityRecord>[];
  }

  static List<NotificationItem> notifications() {
    final DateTime now = DateTime.now();
    return <NotificationItem>[
      NotificationItem(
        title: 'Lastik kontrolü hatırlatması',
        message: 'Euclid-2 aracının sağ ön lastiği 30 günü geçti.',
        date: now.subtract(const Duration(hours: 3)),
        kind: NotificationKind.tire,
      ),
      NotificationItem(
        title: 'Yağ takviyesi planlandı',
        message: 'XCMG-13 için hidrolik yağ takviyesi bekleniyor.',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        kind: NotificationKind.oil,
      ),
      NotificationItem(
        title: 'Form onaylandı',
        message: 'Dün gönderdiğiniz bakım formu bakım şefi tarafından onaylandı.',
        date: now.subtract(const Duration(days: 2)),
        kind: NotificationKind.form,
        read: true,
      ),
    ];
  }
}
