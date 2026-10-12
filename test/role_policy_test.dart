import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/models/models.dart';
import 'package:nimo_arizabakim/services/role_policy.dart';

Map<String, dynamic> user(Object? role) => <String, dynamic>{'role': role};

void main() {
  test('rol turu Atolye Bakim Personeli olan her rol kabul edilir', () {
    // Listede olmayan, sonradan eklenmiş bir rol: türünden kabul edilir.
    for (final Map<String, dynamic> json in <Map<String, dynamic>>[
      user(<String, dynamic>{'name': 'Yeni Atölye Rolü', 'type': 'Atölye Bakım Personeli'}),
      user(<String, dynamic>{
        'name': 'Yeni Atölye Rolü',
        'group': <String, dynamic>{'name': 'ATÖLYE BAKIM PERSONELİ'},
      }),
      <String, dynamic>{'role': 'Yeni Atölye Rolü', 'roleType': 'atolye bakim personeli'},
      <String, dynamic>{
        'roles': <Object?>[
          <String, dynamic>{'category': 'Atölye Bakım Personeli'},
        ],
      },
    ]) {
      expect(RolePolicy.canUseApp(json), isTrue, reason: '$json');
    }
  });

  test('Bakim Yoneticisi rozetli roller kabul edilir', () {
    for (final Map<String, dynamic> json in <Map<String, dynamic>>[
      user(<String, dynamic>{'name': 'Atölye Bakım Yöneticisi', 'badge': 'Bakım Yöneticisi'}),
      user(<String, dynamic>{'name': 'Yeni Yönetici Rolü', 'badge': 'BAKIM YÖNETİCİSİ'}),
      <String, dynamic>{'role': 'Yeni Yönetici Rolü', 'badge': 'Bakım Yöneticisi'},
      user('ATÖLYE BAKIM YÖNETİCİSİ'),
      user(<String, dynamic>{'name': 'Atölye Bakım Yöneticisi'}),
    ]) {
      expect(RolePolicy.canUseApp(json), isTrue, reason: '$json');
    }
  });

  test('tur bilgisi yoksa bilinen atolye rolleri kabul edilir', () {
    for (final String role in <String>[
      'Mekanik Bakım Kalker',
      'MEKANİK BAKIM KALKER',
      'Boya/Kaporta İşleri',
      'Elektrik Bakım Ekibi Oto 24V',
      'Atölye Bakım',
    ]) {
      expect(RolePolicy.canUseApp(user(role)), isTrue, reason: role);
      expect(RolePolicy.canUseApp(user(<String, dynamic>{'name': role})), isTrue,
          reason: role);
    }
  });

  test('baska tur ve roller reddedilir', () {
    for (final Map<String, dynamic> json in <Map<String, dynamic>>[
      user('ŞOFÖR'),
      user(<String, dynamic>{'name': 'ŞOFÖR', 'type': 'Operatör'}),
      user('Atölye Bakım Şefi'),
      user(''),
      <String, dynamic>{},
    ]) {
      expect(RolePolicy.canUseApp(json), isFalse, reason: '$json');
    }
  });

  test('rol duz metin ya da nesne olarak okunur', () {
    expect(UserProfile.roleFromJson(user('Mekanik Bakım Kalker')), 'Mekanik Bakım Kalker');
    expect(
      UserProfile.roleFromJson(user(<String, dynamic>{'id': 7, 'name': 'Atölye Bakım'})),
      'Atölye Bakım',
    );
    expect(UserProfile.roleFromJson(<String, dynamic>{'roleName': 'ŞOFÖR'}), 'ŞOFÖR');
    expect(UserProfile.roleFromJson(<String, dynamic>{'name': 'Şahin'}), '');
  });

  test('beyaz listedeki telefon numaralari (0544 376 09 10) rolune bakilmaksizin kabul edilir', () {
    // Hamza'nın backend rolü: Operasyonel Görev Yöneticisi
    final Map<String, dynamic> hamzaJson = <String, dynamic>{
      'fullName': 'Hamza Çonlu',
      'mail': 'hamza29971@gmail.com',
      'role': <String, dynamic>{'name': 'Operasyonel Görev Yöneticisi', 'isAdmin': true},
    };

    expect(RolePolicy.canUseApp(hamzaJson, phoneNumber: '05443760910'), isTrue);
    expect(RolePolicy.canUseApp(hamzaJson, phoneNumber: '0544 376 09 10'), isTrue);
    expect(RolePolicy.canUseApp(hamzaJson, phoneNumber: '+90 544 376 09 10'), isTrue);
    expect(RolePolicy.canUseApp(hamzaJson), isTrue); // e-postadan da tanır

    // Bilinmeyen telefon ve yetkisiz rol reddedilmeli
    expect(
      RolePolicy.canUseApp(
        <String, dynamic>{'role': 'ŞOFÖR'},
        phoneNumber: '0555 111 22 33',
      ),
      isFalse,
    );
  });
}
