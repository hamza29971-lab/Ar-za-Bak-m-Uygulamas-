import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/widgets/vehicle_photo.dart';

void main() {
  test('paletli araclar model grubunun gorselini kullanir', () {
    for (final String code in <String>['Hitachi-1200', 'Hitachi-1800', 'Hitachi-1900']) {
      expect(vehicleOwnPhoto(code), 'assets/images/Hitachi-1800.png', reason: code);
    }
    for (final String code in <String>['Hitachi-490-1', 'Hitachi-490-2']) {
      expect(vehicleOwnPhoto(code), 'assets/images/Hitachi 490.png', reason: code);
    }
    for (final String code in <String>[
      'Sany-68', 'Sany-69', 'Sany-70',
      'Komatsu-4', 'Komatsu-5', 'Komatsu-K6', 'Komatsu-K7', 'Komatsu-K8',
    ]) {
      expect(vehicleOwnPhoto(code), 'assets/images/Sany.png', reason: code);
    }
  });

  test('eslenen gorsel dosyalari gercekten var', () {
    for (final String path in <String>[
      'assets/images/Hitachi-1800.png',
      'assets/images/Hitachi 490.png',
      'assets/images/Sany.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
