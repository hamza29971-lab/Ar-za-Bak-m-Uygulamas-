import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/models/models.dart';
import 'package:nimo_arizabakim/state/app_state.dart';

Vehicle? byCode(AppState state, String code) =>
    state.vehicles.where((Vehicle v) => v.code == code).firstOrNull;

void main() {
  test('dizin bilinmiyorsa yerel filo yerel kodlarla gosterilir', () {
    final AppState state = AppState();
    expect(byCode(state, 'Euclid-2')!.name, 'Euclid-2');
  });

  test('listede sunucudaki ad gosterilir, eslesmeyen yerel arac gizlenir', () {
    final AppState state = AppState();
    state.seedVehicleDirectory(<String, String>{
      '05-01-IM-KK-EUCLID.02': 'uuid-euclid-2',
    });

    expect(byCode(state, 'Euclid-2')!.name, '05-01-IM-KK-EUCLID.02');
    expect(byCode(state, 'Euclid-3'), isNull);
    expect(state.filterVehicles('EUCLID.02').single.code, 'Euclid-2');
  });

  test('UUID ayni kalip isim degisince listedeki ad guncellenir', () {
    final AppState state = AppState();
    state.seedVehicleDirectory(<String, String>{
      '05-01-IM-KK-EUCLID.02': 'uuid-euclid-2',
    });
    state.selectVehicle(byCode(state, 'Euclid-2'));

    state.seedVehicleDirectory(<String, String>{
      'YENI-AD-EUCLID-02': 'uuid-euclid-2',
    });

    expect(byCode(state, 'Euclid-2')!.name, 'YENI-AD-EUCLID-02');
    expect(state.vehicleUuidFor('Euclid-2'), 'uuid-euclid-2');
    expect(state.selectedVehicle!.name, 'YENI-AD-EUCLID-02');
  });

  test('uygulamada karsiligi olmayan tipi tanimsiz arac listelenmez', () {
    final AppState state = AppState();
    state.seedVehicleDirectory(<String, String>{
      '05-01-IM-KK-EUCLID.02': 'uuid-euclid-2',
      '05-01-IM-KK-BELAZ.77': 'uuid-belaz-77',
    });

    expect(
      state.vehicles.where((Vehicle v) => v.name == '05-01-IM-KK-BELAZ.77'),
      isEmpty,
    );
    expect(state.vehicles.every((Vehicle v) => v.type.isNotEmpty), isTrue);
  });
}
