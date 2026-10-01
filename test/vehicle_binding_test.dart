import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/services/vehicle_binding_store.dart';
import 'package:nimo_arizabakim/services/vehicle_directory_service.dart';

/// Yerel araç kodlarıyla sunucu etiketlerini `MARKA#NUMARA` biçiminde
/// eşleştiren basit anahtar; [AppState]'tekinin test karşılığı.
String? key(String label) {
  final String upper = label.toUpperCase();
  final String brand = upper.contains('EUCLID') || upper.contains('EUC')
      ? 'EUCLID'
      : upper.contains('XCMG')
          ? 'XCMG'
          : '';
  if (brand.isEmpty) return null;
  final RegExpMatch? m = RegExp(r'(\d+)\s*$').firstMatch(upper.trim());
  if (m == null) return null;
  return '$brand#${int.parse(m.group(1)!)}';
}

VehicleDirectoryEntry entry(String id, String label) =>
    VehicleDirectoryEntry(id: id, label: label);

void main() {
  late VehicleBindingStore store;

  setUp(() => store = VehicleBindingStore(canonicalKey: key));

  test('ilk cekimde isim uzerinden bag kurulur', () {
    final VehicleDirectorySync sync = store.reconcile(
      entries: <VehicleDirectoryEntry>[entry('uuid-2', '05-01-IM-KK-EUCLID.02')],
      localCodes: <String>['Euclid-2'],
    );

    expect(sync.newlyBound, <String>['Euclid-2']);
    expect(store.uuidFor('Euclid-2'), 'uuid-2');
    expect(sync.unmatched, isEmpty);
  });

  test('sunucuda isim degisse de UUID bagi korunur', () {
    store.reconcile(
      entries: <VehicleDirectoryEntry>[entry('uuid-2', '05-01-IM-KK-EUCLID.02')],
      localCodes: <String>['Euclid-2'],
    );

    // Ayni UUID, tamamen farkli bir isim: eskiden bu bagi kopariyordu.
    final VehicleDirectorySync sync = store.reconcile(
      entries: <VehicleDirectoryEntry>[entry('uuid-2', 'KAMYON-YENI-AD')],
      localCodes: <String>['Euclid-2'],
    );

    expect(store.uuidFor('Euclid-2'), 'uuid-2');
    expect(sync.renamed, hasLength(1));
    expect(sync.renamed.single.localCode, 'Euclid-2');
    expect(sync.renamed.single.from, '05-01-IM-KK-EUCLID.02');
    expect(sync.renamed.single.to, 'KAMYON-YENI-AD');
    expect(sync.unmatched, isEmpty);
  });

  test('ayni isimle ikinci cekimde yeniden adlandirma bildirilmez', () {
    final List<VehicleDirectoryEntry> entries = <VehicleDirectoryEntry>[
      entry('uuid-2', '05-01-IM-KK-EUCLID.02'),
    ];
    store.reconcile(entries: entries, localCodes: <String>['Euclid-2']);
    final VehicleDirectorySync sync =
        store.reconcile(entries: entries, localCodes: <String>['Euclid-2']);

    expect(sync.renamed, isEmpty);
    expect(sync.newlyBound, isEmpty);
  });

  test('arac sunucu listesinden dusunce bag silinmez, kayip isaretlenir', () {
    store.reconcile(
      entries: <VehicleDirectoryEntry>[entry('uuid-2', 'EUCLID 2')],
      localCodes: <String>['Euclid-2'],
    );

    final VehicleDirectorySync sync = store.reconcile(
      entries: <VehicleDirectoryEntry>[entry('uuid-9', 'EUCLID 9')],
      localCodes: <String>['Euclid-2', 'Euclid-9'],
    );

    // Bag duruyor: sunucu gecici olarak eksik liste donmus olabilir.
    expect(store.uuidFor('Euclid-2'), 'uuid-2');
    expect(sync.missing, contains('Euclid-2'));
    expect(store.bindings['Euclid-2']!.missingSince, isNotNull);
  });

  test('kayip arac geri gelince isaret temizlenir', () {
    final List<VehicleDirectoryEntry> full = <VehicleDirectoryEntry>[
      entry('uuid-2', 'EUCLID 2'),
    ];
    store.reconcile(entries: full, localCodes: <String>['Euclid-2']);
    store.reconcile(
      entries: <VehicleDirectoryEntry>[entry('uuid-9', 'EUCLID 9')],
      localCodes: <String>['Euclid-2'],
    );
    expect(store.bindings['Euclid-2']!.missingSince, isNotNull);

    store.reconcile(entries: full, localCodes: <String>['Euclid-2']);
    expect(store.bindings['Euclid-2']!.missingSince, isNull);
  });

  test('eslesmeyen arac bildirilir', () {
    final VehicleDirectorySync sync = store.reconcile(
      entries: <VehicleDirectoryEntry>[entry('uuid-7', 'BILINMEYEN MARKA 7')],
      localCodes: <String>['Euclid-2'],
    );

    expect(sync.unmatched, <String>['Euclid-2']);
    expect(store.uuidFor('Euclid-2'), isNull);
    expect(sync.serverOnly, <String>['BILINMEYEN MARKA 7']);
  });

  test('bir UUID iki yerel araca baglanmaz', () {
    final VehicleDirectorySync sync = store.reconcile(
      entries: <VehicleDirectoryEntry>[entry('uuid-2', 'EUCLID 2')],
      localCodes: <String>['Euclid-2', 'Euclid-2-kopya'],
    );

    expect(sync.newlyBound, hasLength(1));
    expect(store.bindings.length, 1);
  });

  test('JSON gidis-donusu bagi korur', () {
    const VehicleBinding binding = VehicleBinding(
      localCode: 'Euclid-2',
      uuid: 'uuid-2',
      serverLabel: 'EUCLID 2',
    );
    final VehicleBinding? back = VehicleBinding.fromJson(binding.toJson());

    expect(back, isNotNull);
    expect(back!.uuid, 'uuid-2');
    expect(back.localCode, 'Euclid-2');
    expect(back.serverLabel, 'EUCLID 2');
    expect(back.missingSince, isNull);
  });
}
