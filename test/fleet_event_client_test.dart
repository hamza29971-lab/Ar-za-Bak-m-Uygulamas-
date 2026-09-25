import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nimo_arizabakim/services/auth_models.dart';
import 'package:nimo_arizabakim/services/fleet_event_client.dart';

/// mining-be'nin gerçekte döndürdüğü cevaplar (2026-09-25'te ölçüldü) ve
/// kullanıcıya gösterilen mesajlar.
void main() {
  const FleetEvent event = FleetEvent(title: 'Yağ Takviyesi', type: 'bakim');

  Future<FleetResult> sendWith(int status, String body) {
    final HttpFleetEventClient client = HttpFleetEventClient(
      client: MockClient((http.Request request) async => http.Response(
            body,
            status,
            headers: <String, String>{'content-type': 'application/json'},
          )),
    );
    return client.send(event, accessToken: 'test-token');
  }

  test('token yoksa (401 UNAUTHORIZED) tekrar giris yapilmasi istenir', () async {
    final FleetResult r = await sendWith(
      401,
      '{"success":false,"code":"UNAUTHORIZED","message":"Yetkisiz erisim"}',
    );
    expect(r.ok, isFalse);
    expect(r.error, contains('tekrar giriş'));
  });

  test('token gecerli ama yetki yoksa (401 duz metin) yetki mesaji gosterilir',
      () async {
    final FleetResult r = await sendWith(
      401,
      'You do not have permission to access this resource.',
    );
    expect(r.ok, isFalse);
    expect(r.error, contains('yetkisi vermiyor'));
    // Eski yaniltici metin artik gosterilmez.
    expect(r.error, isNot(contains('Sunucu anahtarı')));
  });

  test('suresi dolmus token (440) oturum suresi mesaji verir', () async {
    final FleetResult r = await sendWith(
      440,
      '{"code":"ACCESS_TOKEN_EXPIRED","message":"Access token expired"}',
    );
    expect(r.ok, isFalse);
    expect(r.error, contains('Oturum süresi doldu'));
  });

  test('201 basarili sayilir ve data.uuid kayit id olarak doner', () async {
    final FleetResult r = await sendWith(
      201,
      '{"success":true,"data":{"uuid":"kayit-123"}}',
    );
    expect(r.ok, isTrue);
    expect(r.id, 'kayit-123');
  });

  group('jwtAuthSummary', () {
    String jwt(Map<String, Object?> claims) {
      String part(Map<String, Object?> m) =>
          base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      return '${part(<String, Object?>{'alg': 'HS256'})}.${part(claims)}.imza';
    }

    test('yetki claimlerini ve claim adlarini dondurur, ham tokeni degil', () {
      final String token = jwt(<String, Object?>{
        'sub': 'kullanici-1',
        'roles': <String>['DRIVER'],
        'exp': 1790000000,
      });
      final Map<String, Object?> s = jwtAuthSummary(token);

      expect(s['jwt'], isTrue);
      expect(s['roles'], <String>['DRIVER']);
      expect(s['claimAdlari'], containsAll(<String>['sub', 'roles', 'exp']));
      expect(s['expUtc'], isNotNull);
      // sub degeri yetkiyle ilgili degil; yalnizca adi listelenir.
      expect(s.containsKey('sub'), isFalse);
      expect(s.toString(), isNot(contains(token)));
    });

    test('JWT olmayan tokeni guvenle reddeder', () {
      expect(jwtAuthSummary('duz-token')['jwt'], isFalse);
      expect(jwtAuthSummary('a.%%%.c')['jwt'], isFalse);
    });
  });
}
