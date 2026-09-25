import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/services/update_service.dart';

/// OTA'nin guncelleme onerip onermeyecegi. Kurulu surum tabletteki gercek
/// versionCode'dur; indirme/kurulum denemesi hicbir seyi "kuruldu" saymaz.
void main() {
  test('uzaktaki surum kuruludan buyukse onerilir', () {
    expect(UpdateService.shouldOffer(remote: 70, installed: 69, ignored: 0), isTrue);
  });

  test('ayni surum kuruluysa onerilmez', () {
    expect(UpdateService.shouldOffer(remote: 70, installed: 70, ignored: 0), isFalse);
  });

  test('daha eski bir surum hicbir zaman onerilmez', () {
    expect(UpdateService.shouldOffer(remote: 68, installed: 70, ignored: 0), isFalse);
  });

  test('"Simdi Degil" denen surum tekrar onerilmez', () {
    expect(UpdateService.shouldOffer(remote: 71, installed: 70, ignored: 71), isFalse);
  });

  test('basarisiz kurulum sonrasi ayni surum yeniden onerilir', () {
    // Eski kod indirme bitince build numarasini "kuruldu" diye kaydediyordu ve
    // pencere bir daha cikmiyordu. Artik karar yalnizca gercek versionCode'a
    // bagli: kurulum olmadiysa versionCode degismez, guncelleme yine onerilir.
    const int installedAfterFailedInstall = 69;
    expect(
      UpdateService.shouldOffer(remote: 70, installed: installedAfterFailedInstall, ignored: 0),
      isTrue,
    );
  });
}
