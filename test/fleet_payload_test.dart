import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/models/models.dart';
import 'package:nimo_arizabakim/models/tire_change_model.dart';
import 'package:nimo_arizabakim/providers/tire_change_provider.dart';
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
    expect(state.vehicleUuidFor('Euclid-10'), isNull);
    // Farkli markadaki bir kayit (KOMT.550.9), numarasi ayni diye baska bir
    // araca (Euclid-9) baglanmaz.
    expect(state.vehicleUuidFor('Euclid-9') == 'uuid-komatsu-9', isFalse);
  });

  test('ARK etiketli kayitlar Euclid-11/12ye baglanir', () {
    final AppState state = AppState();
    // Sunucuda Euclid-11/12'nin karsiligi ayri bir "ARK" markasi altinda.
    state.seedVehicleDirectory(<String, String>{
      'ARK 11': 'uuid-ark-11',
      'ARK 12': 'uuid-ark-12',
    });

    expect(state.vehicleUuidFor('Euclid-11'), 'uuid-ark-11');
    expect(state.vehicleUuidFor('Euclid-12'), 'uuid-ark-12');
  });

  test('paletli araclarin markalari da sunucu isimlendirmesiyle eslesir', () {
    final AppState state = AppState();
    state.seedVehicleDirectory(<String, String>{
      // HITCEX1200 gibi marka+numara bitisik tokenlar.
      '05-05-IM-PM-HITCEX1200': 'uuid-hitachi-1200',
      '05-05-IM-PM-HITCEX1800': 'uuid-hitachi-1800',
      // HITC.490.1 / .2: marka ayri token, son basamak tek rakam.
      '05-05-IM-PM-HITC.490.1': 'uuid-hitachi-490-1',
      '05-05-IM-PM-HITC.490.2': 'uuid-hitachi-490-2',
      '05-05-IM-PM-SY.385H.68': 'uuid-sany-68',
      '05-05-IM-PM-KOMT.550.9': 'uuid-komatsu-9',
      // Sunucuda 2026-09-22'de görülen gerçek kayıtlar: marka "LUIGONG"
      // (harfler yer değişmiş), numara bazen "K" önekiyle (K4/K5) bazen
      // ayrı model koduyla ("PC 550 -6") geliyor.
      'KOMATSU K4': 'uuid-komatsu-4',
      'KOMATSU PC 550  -6': 'uuid-komatsu-6',
      'LUIGONG 6': 'uuid-liugong-6',
      'LUIGONG 7': 'uuid-liugong-7',
      'LUIGONG LODER L40': 'uuid-liugong-40',
      'LUIGONG LODER L41': 'uuid-liugong-41',
    });

    expect(state.vehicleUuidFor('Hitachi-1200'), 'uuid-hitachi-1200');
    expect(state.vehicleUuidFor('Hitachi-1800'), 'uuid-hitachi-1800');
    expect(state.vehicleUuidFor('Hitachi-490-1'), 'uuid-hitachi-490-1');
    expect(state.vehicleUuidFor('Hitachi-490-2'), 'uuid-hitachi-490-2');
    expect(state.vehicleUuidFor('Sany-68'), 'uuid-sany-68');
    expect(state.vehicleUuidFor('Komatsu-4'), 'uuid-komatsu-4');
    expect(state.vehicleUuidFor('Komatsu-K6'), 'uuid-komatsu-6');
    expect(state.vehicleUuidFor('Liugong-6'), 'uuid-liugong-6');
    expect(state.vehicleUuidFor('Liugong-7'), 'uuid-liugong-7');
    expect(state.vehicleUuidFor('Liugong-40'), 'uuid-liugong-40');
    expect(state.vehicleUuidFor('Liugong-41'), 'uuid-liugong-41');
    // Bu sahte dizinde hic karsiligi olmayan bir arac gercekten eslesmemeli.
    expect(state.vehicleUuidFor('Euclid-12'), isNull);
    // Yerel filoda "Komatsu-9" yok (yalnizca 4/5/K6-K9 eklendi); yine de
    // eslestirme mekanizmasinin kendisi dogru calisiyor mu diye ayri kontrol.
    expect(state.vehicleUuidFor('Komatsu-9'), 'uuid-komatsu-9');
  });

  test('paletli araclar lastiksiz olarak filoya eklenmis', () {
    final AppState state = AppState();
    const List<String> codes = <String>[
      'Hitachi-1200', 'Hitachi-1800', 'Hitachi-1900',
      'Hitachi-490-1', 'Hitachi-490-2',
      'Sany-68', 'Sany-69', 'Sany-70',
      'Liugong-6', 'Liugong-7', 'Liugong-40', 'Liugong-41',
      'Komatsu-4', 'Komatsu-5', 'Komatsu-K6', 'Komatsu-K7', 'Komatsu-K8',
    ];
    for (final String code in codes) {
      final Vehicle vehicle =
          state.vehicles.firstWhere((Vehicle v) => v.code == code);
      expect(vehicle.tirePositions, isEmpty, reason: code);
      expect(vehicle.tireCount, 0, reason: code);
    }

    // K9 sunucuda hic yok; filodan cikarildi.
    expect(state.vehicles.any((Vehicle v) => v.code == 'Komatsu-K9'), isFalse);

    // Paletli araclar Lastik Degisimi kataloguna hic eklenmez (yalnizca
    // global filoda/Yag Takviyesi'nde var).
    for (final String code in codes) {
      expect(
        TireChangeProvider().vehicles.any((VehicleModel v) => v.name == code),
        isFalse,
        reason: code,
      );
    }
  });

  test('Lastik Degisimi araç listesi kategoriye gore filtrelenir', () {
    final TireChangeProvider provider = TireChangeProvider();
    final int total = provider.filteredVehicles.length;

    // Bu ekranda yalnizca lastikli araclar oldugu icin Kamyon ve Loder
    // kategorileri gorunmeli, Ekskavatör (paletli) hic gorunmemeli.
    expect(provider.vehicleCategories, <String>['Kamyon', 'Loder']);

    provider.setTypeFilter('Kamyon');
    final List<VehicleModel> trucks = provider.filteredVehicles;
    expect(trucks, isNotEmpty);
    expect(trucks.length, lessThan(total));
    for (final VehicleModel v in trucks) {
      expect(v.category, 'Kamyon', reason: v.name);
    }

    // Arama ile birlikte calisir.
    provider.updateSearch('Euclid-3');
    expect(provider.filteredVehicles.single.name, 'Euclid-3');

    // Filtre kaldirilinca liste eski haline doner.
    provider.clearSearch();
    provider.setTypeFilter(null);
    expect(provider.filteredVehicles.length, total);
  });

  test('Shovel de dahil paletli araclarin tumu Ekskavator kategorisinde', () {
    final AppState state = AppState();
    const List<String> excavatorCodes = <String>[
      'Hitachi-1200', 'Hitachi-1800', 'Hitachi-1900', // Shovel
      'Hitachi-490-1', 'Hitachi-490-2',
      'Sany-68', 'Sany-69', 'Sany-70',
      'Liugong-6', 'Liugong-7',
      'Komatsu-4', 'Komatsu-5', 'Komatsu-K6', 'Komatsu-K7', 'Komatsu-K8',
    ];
    for (final String code in excavatorCodes) {
      final Vehicle vehicle =
          state.vehicles.firstWhere((Vehicle v) => v.code == code);
      expect(vehicle.category, 'Ekskavatör', reason: code);
    }
    // Loder Elektrikli araclar Ekskavator degil, Loder kategorisinde.
    expect(state.vehicles.firstWhere((Vehicle v) => v.code == 'Liugong-40').category, 'Loder');
  });

  test('arac tipi etiketleri istenen gruplarla eslesir', () {
    final AppState state = AppState();
    String typeLabelOf(String code) =>
        state.vehicles.firstWhere((Vehicle v) => v.code == code).typeLabel;

    // Euclid 1/2 ve 9-12: E.Kamyon. Euclid 3-8: K. Kamyon.
    for (final String code in <String>['Euclid-1', 'Euclid-2', 'Euclid-9', 'Euclid-10', 'Euclid-11', 'Euclid-12']) {
      expect(typeLabelOf(code), 'E.Kamyon', reason: code);
    }
    for (int i = 3; i <= 8; i++) {
      expect(typeLabelOf('Euclid-$i'), 'K. Kamyon', reason: 'Euclid-$i');
    }
    // XCMG ve Liugong 16-20: E.Kamyon.
    for (int i = 13; i <= 15; i++) {
      expect(typeLabelOf('XCMG-$i'), 'E.Kamyon', reason: 'XCMG-$i');
    }
    for (int i = 16; i <= 20; i++) {
      expect(typeLabelOf('Liugong-$i'), 'E.Kamyon', reason: 'Liugong-$i');
    }
    // Liugong 33-39 ve 40/41: Loder Elektrikli.
    for (int i = 33; i <= 39; i++) {
      expect(typeLabelOf('Liugong-$i'), 'Loder Elektrikli', reason: 'Liugong-$i');
    }
    expect(typeLabelOf('Liugong-40'), 'Loder Elektrikli');
    expect(typeLabelOf('Liugong-41'), 'Loder Elektrikli');
    // Hitachi 1200/1800/1900: Shovel. Hitachi 490 serisi: Ekskavatör Dizel.
    for (final String code in <String>['Hitachi-1200', 'Hitachi-1800', 'Hitachi-1900']) {
      expect(typeLabelOf(code), 'Shovel', reason: code);
    }
    expect(typeLabelOf('Hitachi-490-1'), 'Ekskavatör Dizel');
    expect(typeLabelOf('Hitachi-490-2'), 'Ekskavatör Dizel');
    // Sany, Liugong 6/7, Komatsu 4/5/K6/K7: Ekskavatör Dizel.
    for (final String code in <String>[
      'Sany-68', 'Sany-69', 'Sany-70',
      'Liugong-6', 'Liugong-7',
      'Komatsu-4', 'Komatsu-5', 'Komatsu-K6', 'Komatsu-K7',
    ]) {
      expect(typeLabelOf(code), 'Ekskavatör Dizel', reason: code);
    }
    // Komatsu K8: Ekskavatör Elektrikli.
    expect(typeLabelOf('Komatsu-K8'), 'Ekskavatör Elektrikli');
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
