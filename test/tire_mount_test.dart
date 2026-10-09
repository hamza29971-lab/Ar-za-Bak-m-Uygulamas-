import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/models/tire_change_model.dart';
import 'package:nimo_arizabakim/providers/tire_change_provider.dart';
import 'package:nimo_arizabakim/services/fleet_event_mapper.dart';
import 'package:nimo_arizabakim/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TireChangeProvider> providerWithVehicle() async {
  final TireChangeProvider provider = TireChangeProvider();
  provider.selectVehicle(provider.vehicles.first);
  await pumpEventQueue();
  return provider;
}

TireRecord tire(TireChangeProvider p, int n) =>
    p.tireRecords.firstWhere((TireRecord r) => r.tireNumber == n);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('ilk kayitta seri no, basinc ve marka kaydedilir', () async {
    final TireChangeProvider p = await providerWithVehicle();
    await p.mountTire(1, serialNumber: 'SN-1', pressure: 100, brand: 'Michelin', coated: true);

    final TireRecord r = tire(p, 1);
    expect(r.serialNumber, 'SN-1');
    expect(r.pressure, 100);
    expect(r.brand, 'Michelin');
    expect(r.coated, isTrue);
    expect(r.hasInitialRecord, isTrue);
    expect(r.previousTires, isEmpty);
  });

  test('degisimde sokulen lastik bilgileriyle gecmise eklenir', () async {
    final TireChangeProvider p = await providerWithVehicle();
    await p.mountTire(1, serialNumber: 'SN-1', pressure: 100, brand: 'Michelin', coated: true);
    await p.resetChangedTires(); // gönderildi
    await p.mountTire(1, serialNumber: 'SN-2', pressure: 105, brand: 'Bridgestone', coated: false);

    final TireRecord r = tire(p, 1);
    expect(r.serialNumber, 'SN-2');
    expect(r.brand, 'Bridgestone');
    expect(r.previousTires, hasLength(1));
    expect(r.previousTires.single.serialNumber, 'SN-1');
    expect(r.previousTires.single.pressure, 100);
    expect(r.previousTires.single.brand, 'Michelin');
    expect(r.previousTires.single.coated, isTrue);
    expect(r.coated, isFalse);
  });

  test('gonderilmemis giris duzeltilince gecmise eklenmez', () async {
    final TireChangeProvider p = await providerWithVehicle();
    await p.mountTire(1, serialNumber: 'SN-1', pressure: 100, brand: 'Michelin', coated: true);
    await p.mountTire(1,
        serialNumber: 'SN-1X', pressure: 98, brand: 'Michelin', coated: false, replacesPending: true);

    final TireRecord r = tire(p, 1);
    expect(r.serialNumber, 'SN-1X');
    expect(r.pressure, 98);
    expect(r.previousTires, isEmpty);
  });

  test('iptal edilince lastik ve gecmisi onceki haline doner', () async {
    final TireChangeProvider p = await providerWithVehicle();
    await p.mountTire(1, serialNumber: 'SN-1', pressure: 100, brand: 'Michelin', coated: true);
    await p.resetChangedTires();
    await p.mountTire(1, serialNumber: 'SN-2', pressure: 105, brand: 'Bridgestone', coated: false);

    await p.discardChanges();

    final TireRecord r = tire(p, 1);
    expect(r.serialNumber, 'SN-1');
    expect(r.pressure, 100);
    expect(r.brand, 'Michelin');
    expect(r.previousTires, isEmpty);
  });

  test('basinc, marka ve gecmis kalici olarak saklanir', () async {
    final TireChangeProvider p = await providerWithVehicle();
    await p.mountTire(1, serialNumber: 'SN-1', pressure: 100, brand: 'Michelin', coated: true);
    await p.resetChangedTires();
    await p.mountTire(1, serialNumber: 'SN-2', pressure: 105.5, brand: 'Bridgestone', coated: false);

    final TireChangeProvider reopened = await providerWithVehicle();
    final TireRecord r = tire(reopened, 1);
    expect(r.serialNumber, 'SN-2');
    expect(r.pressure, 105.5);
    expect(r.brand, 'Bridgestone');
    expect(r.coated, isFalse);
    expect(r.previousTires.single.serialNumber, 'SN-1');
    expect(r.previousTires.single.coated, isTrue);
  });

  test('gonderimde basinc ve marka okunur alan adlariyla gider', () {
    final PendingOperation op = PendingOperation(
      kind: PendingKind.tire,
      vehicleCode: 'Euclid-1',
      label: 'Lastik #1 değiştirildi (SN-2)',
      date: DateTime(2026, 10, 9),
      payload: <String, Object?>{
        'op': 'degisim',
        'tireId': 'Lastik #1',
        'position': 'Ön sağ',
        'serialNo': 'SN-2',
        'pressure': 105.0,
        'pressureUnit': tirePressureUnit,
        'brand': 'Bridgestone',
        'coating': 1,
        'previousSerialNo': 'SN-1',
        'previousPressure': 100.0,
        'previousBrand': 'Michelin',
        'previousCoating': 1,
        'previousMountedAt': '2026-09-01T08:00:00.000Z',
        'previousRemovedAt': '2026-10-09T08:00:00.000Z',
      },
    );
    final Map<String, Object?> fields = FleetEventMapper.fromPending(
      op,
      deviceId: null,
      user: null,
      vehicleUUID: 'uuid-1',
    ).toJson()['fields']! as Map<String, Object?>;

    expect(fields['seriNo'], 'SN-2');
    expect(fields['havaBasinci'], 105.0);
    expect(fields['basincBirimi'], 'PSI');
    expect(fields['lastikMarkasi'], 'Bridgestone');
    expect(fields['Kaplama'], 1);
    expect(fields['oncekiSeriNo'], 'SN-1');
    expect(fields['oncekiHavaBasinci'], 100.0);
    expect(fields['oncekiLastikMarkasi'], 'Michelin');
    expect(fields['oncekiKaplama'], 1);
    expect(fields['oncekiTakilmaTarihi'], '2026-09-01T08:00:00.000Z');
    expect(fields['oncekiCikarilmaTarihi'], '2026-10-09T08:00:00.000Z');
    expect(fields.length, lessThanOrEqualTo(20));
  });

  test('basinc gosterimi', () {
    expect(formatTirePressure(100), '100 PSI');
    expect(formatTirePressure(105.5), '105.5 PSI');
    expect(formatTirePressure(null), '---');
  });
}
