import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/models/models.dart';
import 'package:nimo_arizabakim/services/fleet_event_client.dart';
import 'package:nimo_arizabakim/services/fleet_event_mapper.dart';
import 'package:nimo_arizabakim/state/app_state.dart';

/// Sunucuya giden gövdenin sözleşmesi.
void main() {
  const UserProfile user = UserProfile(
    fullName: 'Şahin Kaya',
    email: 's@example.com',
    phone: '05321234567',
    role: 'ŞOFÖR',
    registryNo: '95674DBC93',
    machineCode: '',
    machineType: '',
  );

  Map<String, Object?> lastOilEvent(AppState state) {
    final PendingOperation op = state.pendingOf(PendingKind.oil).last;
    return FleetEventMapper.fromPending(
      op,
      deviceId: null,
      user: user,
      vehicleUUID: state.vehicleUuidFor(op.vehicleCode),
    ).toJson();
  }

  Map<String, Object?> fieldsOf(Map<String, Object?> json) =>
      json['fields']! as Map<String, Object?>;

  test('sunucudaki isimlendirme yerel arac koduyla eslesir', () {
    final AppState state = AppState();
    // mining-be'nin search-auto-complete cevabindan birebir alinmis adlar.
    state.seedVehicleDirectory(<String, String>{
      '05-01-IM-KK-EUCLID.02': 'uuid-euclid-2',
      '05-01-IM-KK-HTC.EUC.09': 'uuid-euclid-9',
      '05-01-IM-KK-XCMG.E.13E': 'uuid-xcmg-13',
      '05-03-IM-LM-LIUG.EL.33': 'uuid-liugong-33',
      '05-05-IM-PM-KOMT.550.9': 'uuid-komatsu-9',
    });

    expect(state.vehicleUuidFor('Euclid-2'), 'uuid-euclid-2');
    expect(state.vehicleUuidFor('Euclid-9'), 'uuid-euclid-9');
    expect(state.vehicleUuidFor('XCMG-13'), 'uuid-xcmg-13');
    expect(state.vehicleUuidFor('Liugong-33'), 'uuid-liugong-33');

    // Sunucuda karsiligi olmayan araclar eslesmez.
    expect(state.vehicleUuidFor('Euclid-12'), isNull);
    // Yalnizca numarasi tutan yabanci bir marka (KOMT.550.9) baglanmaz.
    expect(state.vehicleUuidFor('Euclid-9') == 'uuid-komatsu-9', isFalse);
  });

  test('her yag olayi secili aracin UUIDsini tasir', () {
    final AppState state = AppState();
    final Vehicle vehicle = state.vehicles.first;
    state.seedVehicleDirectory(<String, String>{vehicle.code: 'uuid-123'});
    final OilRecord record = OilRecord(
      areaId: 'YT-01',
      oilType: 'Adblue',
      category: OilCategory.refill,
      amount: 0,
    );

    state.refillOil(vehicle, record, 23.0, product: 'MAXIGEAR EP 80W-90');
    expect(lastOilEvent(state)['vehicleUUID'], 'uuid-123');

    state.checkOil(vehicle, record);
    expect(lastOilEvent(state)['vehicleUUID'], 'uuid-123');
  });

  test('seviye kontrolu son takviyenin miktar ve urununu bildirir', () {
    final AppState state = AppState();
    final Vehicle vehicle = state.vehicles.first;
    final OilRecord record = OilRecord(
      areaId: 'MN-01',
      oilType: 'Arm',
      category: OilCategory.manual,
      amount: 0,
    );

    state.refillOil(vehicle, record, 12.5, product: 'SUPER GRES EP-2');
    state.checkOil(vehicle, record);

    final Map<String, Object?> fields = fieldsOf(lastOilEvent(state));
    expect(fields['islem'], 'kontrol');
    expect(fields['miktarLitre'], 12.5);
    expect(fields['urun'], 'SUPER GRES EP-2');
  });

  test('hic takviye yapilmamissa miktar ve urun gonderilmez', () {
    final AppState state = AppState();
    final OilRecord fresh = OilRecord(
      areaId: 'MN-02',
      oilType: 'Bom',
      category: OilCategory.manual,
      amount: 0,
    );

    state.checkOil(state.vehicles.first, fresh);

    final Map<String, Object?> fields = fieldsOf(lastOilEvent(state));
    expect(fields.containsKey('miktarLitre'), isFalse);
    expect(fields.containsKey('urun'), isFalse);
  });

  test('iptal edilen takviye urunu de geri alir', () {
    final AppState state = AppState();
    final Vehicle vehicle = state.vehicles.first;
    final OilRecord record = OilRecord(
      areaId: 'YT-02',
      oilType: 'Motor',
      category: OilCategory.refill,
      amount: 0,
    );

    state.refillOil(vehicle, record, 30, product: 'YENI URUN');
    state.cancelOilRefill(state.pendingOf(PendingKind.oil).last);

    expect(record.lastProduct, '');
    expect(record.amount, 0);
  });

  test('mekanik operasyon servis saati gondermez', () {
    final Map<String, Object?> fields = fieldsOf(
      FleetEventMapper.fromReport(
        reportType: 'Mekanik Operasyon',
        description: 'Revizyon',
        imageCount: 0,
        imageNames: const <String>[],
        deviceId: null,
        vehicleUUID: 'Liugong-35',
        operatorLabel: '95674DBC93',
        occurredAt: DateTime.utc(2026, 9, 9),
      ).toJson(),
    );

    expect(fields.containsKey('baslangicSaati'), isFalse);
    expect(fields.containsKey('bitisSaati'), isFalse);
  });

  test('servis raporu servis saatini tasir', () {
    final Map<String, Object?> fields = fieldsOf(
      FleetEventMapper.fromReport(
        reportType: 'Servis Raporu',
        description: 'Kacak',
        imageCount: 0,
        imageNames: const <String>[],
        deviceId: null,
        vehicleUUID: 'Euclid-2',
        operatorLabel: '95674DBC93',
        occurredAt: DateTime.utc(2026, 9, 9),
        startTime: '08:30',
        endTime: '10:15',
      ).toJson(),
    );

    expect(fields['baslangicSaati'], '08:30');
    expect(fields['bitisSaati'], '10:15');
  });
}
