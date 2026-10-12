
import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/data/fleet.dart';
import 'package:nimo_arizabakim/data/vehicle_filters.dart';
import 'package:nimo_arizabakim/models/models.dart';

void main() {
  test('every vehicle in fleet has non-empty filters', () {
    for (final Vehicle v in Fleet.vehicles()) {
      final List<String> filters = VehicleFilters.filtersFor(v);
      expect(filters, isNotEmpty, reason: 'Vehicle ${v.code} has empty filter list');
    }
  });
}
