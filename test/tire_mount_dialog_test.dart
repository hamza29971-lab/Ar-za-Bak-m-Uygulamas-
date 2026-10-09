import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/providers/tire_change_provider.dart';
import 'package:nimo_arizabakim/state/app_state.dart';
import 'package:nimo_arizabakim/theme/app_theme.dart';
import 'package:nimo_arizabakim/ui/screens/tire_change_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test ortamının varsayılan yazı tipi her harfi kare çizer ve metinleri
/// gerçekte olduğundan çok daha geniş ölçer; taşma kontrolü anlamlı olsun
/// diye Flutter SDK'daki Roboto yüklenir.
Future<void> loadRoboto() async {
  Directory dir = File(Platform.resolvedExecutable).parent;
  while (!Directory('${dir.path}/material_fonts').existsSync()) {
    if (dir.parent.path == dir.path) return;
    dir = dir.parent;
  }
  final FontLoader loader = FontLoader('Roboto');
  for (final String weight in <String>['regular', 'medium', 'bold']) {
    final File font = File('${dir.path}/material_fonts/roboto-$weight.ttf');
    if (font.existsSync()) {
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(font.readAsBytesSync())));
    }
  }
  await loader.load();
}

/// Uygulama teması. Çerçeveli butonların yazı stili yazı tipi belirtmiyor;
/// cihazda sistem yazı tipi devreye girer, test ortamında ise kare harfli
/// yedek tipe düşüp butonları olduğundan çok geniş ölçer. Testte o boşluk
/// cihazdaki gibi Roboto ile doldurulur.
ThemeData testTheme() {
  final ThemeData base = AppTheme.light();
  return base.copyWith(
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style!.copyWith(
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

/// Lastik Değişimi: seri no, hava basıncı ve marka pencereden girilir.
void main() {
  setUpAll(loadRoboto);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<(AppState, TireChangeProvider)> pumpScreen(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final AppState state = AppState();
    final TireChangeProvider provider = TireChangeProvider();
    provider.selectVehicle(provider.vehicles.first);

    await tester.pumpWidget(
      ChangeNotifierProvider<TireChangeProvider>.value(
        value: provider,
        child: AppScope(
          state: state,
          child: MaterialApp(
            theme: testTheme(),
            home: const Scaffold(body: TireChangeScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (state, provider);
  }

  Finder dialogField(int index) => find
      .descendant(of: find.byType(AlertDialog), matching: find.byType(TextField))
      .at(index);

  Future<void> fill(WidgetTester tester, String serial, String pressure, String brand,
      {required bool coated}) async {
    await tester.enterText(dialogField(0), serial);
    await tester.enterText(dialogField(1), pressure);
    // Marka elle yazilmaz, sabit listeden secilir.
    final Finder brandChoice = find.descendant(
        of: find.byType(AlertDialog), matching: find.text(brand));
    await tester.ensureVisible(brandChoice);
    await tester.pumpAndSettle();
    await tester.tap(brandChoice);
    await tester.pump();
    final Finder choice = find.descendant(
        of: find.byType(AlertDialog), matching: find.text(coated ? 'Evet' : 'Hayır'));
    // Değişim penceresi uzun; seçenekler kaydırılarak görünür hale getirilir.
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pump();
  }

  testWidgets('ilk kayit ve degisim pencereden yapilir, gecmis gorunur',
      (WidgetTester tester) async {
    final (AppState state, TireChangeProvider provider) =
        await pumpScreen(tester, const Size(1280, 800));

    // Tablo yeni sütunları gösterir.
    expect(find.text('Basınç'), findsOneWidget);
    expect(find.text('Marka'), findsOneWidget);

    // İlk lastik kaydı penceresi açılır; boş kaydetmeye izin verilmez.
    await tester.tap(find.text('İlk lastik kaydı').first);
    await tester.pumpAndSettle();
    expect(find.text('İlk Lastik Kaydı'), findsOneWidget);
    await tester.tap(find.text('İlk Lastik Kaydını Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Seri numarasını girin.'), findsOneWidget);
    expect(find.text('Hava basıncını girin.'), findsOneWidget);
    expect(find.text('Lastik markasını seçin.'), findsOneWidget);
    expect(find.text('Kaplama yapılıp yapılmadığını seçin.'), findsOneWidget);

    await fill(tester, 'SN-1', '100', 'Michelin', coated: true);
    await tester.tap(find.text('İlk Lastik Kaydını Kaydet'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('SN-1'), findsOneWidget);
    expect(find.text('100 PSI'), findsOneWidget);
    expect(find.text('Michelin'), findsOneWidget);
    final List<PendingOperation> pending = state.pendingOf(PendingKind.tire);
    expect(pending, hasLength(1));
    expect(pending.single.payload['op'], 'ilk_kayit');
    expect(pending.single.payload['pressure'], 100.0);
    expect(pending.single.payload['brand'], 'Michelin');
    expect(pending.single.payload['coating'], 1);

    // Gönderilmeden tekrar açılırsa değerler dolu gelir ve kuyrukta ikinci
    // bir işlem oluşmaz.
    await tester.tap(find.text('Değiştir').first);
    await tester.pumpAndSettle();
    expect(find.text('İlk Lastik Kaydını Kaydet'), findsOneWidget);
    expect(find.text('Bu kayıt henüz gönderilmedi; bilgileri düzeltebilirsiniz.'),
        findsOneWidget);
    await tester.enterText(dialogField(1), '98');
    await tester.tap(find.text('İlk Lastik Kaydını Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('98 PSI'), findsOneWidget);
    expect(state.pendingOf(PendingKind.tire), hasLength(1));
    expect(state.pendingOf(PendingKind.tire).single.payload['pressure'], 98.0);

    // Gönderildi say: sonraki "Değiştir" gerçek bir değişimdir.
    await provider.resetChangedTires();
    state.clearPending(PendingKind.tire);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Değiştir').first);
    await tester.pumpAndSettle();
    expect(find.text('Lastik Değişimi'), findsWidgets);
    expect(find.text('Sökülecek lastik'), findsOneWidget);

    // Vazgeç hiçbir şeyi değiştirmez.
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(state.pendingOf(PendingKind.tire), isEmpty);
    expect(find.text('SN-1'), findsOneWidget);

    await tester.tap(find.text('Değiştir').first);
    await tester.pumpAndSettle();
    await fill(tester, 'SN-1', '105', 'Brigestone', coated: false);
    await tester.tap(find.text('Değişimi Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni lastiğin seri numarası sökülen lastikle aynı olamaz.'),
        findsOneWidget);

    await tester.enterText(dialogField(0), 'SN-2');
    await tester.tap(find.text('Değişimi Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('SN-2'), findsOneWidget);
    expect(find.text('105 PSI'), findsOneWidget);
    expect(find.text('Brigestone'), findsOneWidget);
    final Map<String, Object?> change = state.pendingOf(PendingKind.tire).single.payload;
    expect(change['op'], 'degisim');
    expect(change['previousSerialNo'], 'SN-1');
    expect(change['previousPressure'], 98.0);
    expect(change['previousBrand'], 'Michelin');
    expect(change['coating'], 0);

    expect(change['previousCoating'], 1);
    expect(change['previousMountedAt'], isA<String>());
    expect(change['previousRemovedAt'], isA<String>());

    // Önceki lastik, satırın en sağındaki butonla açılan pencerede görülür.
    // Önceki lastiği olmayan satırlarda buton görünmez.
    expect(find.text('Önceki Lastik'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // "Önceki Lastik", "Kontrol" ile aynı yükseklikte ve onun sağında durur;
    // üstüne binmez.
    Rect buttonRect(String label) => tester.getRect(find
        .ancestor(of: find.text(label), matching: find.byType(ElevatedButton))
        .first);
    final Rect previousBtn = buttonRect('Önceki Lastik');
    final Rect controlBtn = tester.getRect(find
        .ancestor(
          of: find.text('Kontrol').first,
          matching: find.byType(ElevatedButton),
        )
        .first);
    expect(previousBtn.height, closeTo(controlBtn.height, 0.5));
    expect(previousBtn.left, greaterThanOrEqualTo(controlBtn.right));
    await tester.tap(find.text('Önceki Lastik'));
    await tester.pumpAndSettle();
    expect(find.text('Önceki Lastik'), findsWidgets);
    expect(find.text('LASTİK BİLGİLERİ'), findsOneWidget);
    for (final String label in <String>[
      'Lastik seri no',
      'Lastik basıncı',
      'Lastik markası',
      'Takıldığı tarih',
      'Çıkartıldığı tarih',
      'Kaplama yapıldı mı',
    ]) {
      expect(find.textContaining(label), findsOneWidget, reason: label);
    }
    final Finder dialog = find.byType(Dialog);
    expect(find.descendant(of: dialog, matching: find.text('SN-1')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('98 PSI')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Michelin')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Evet')), findsOneWidget);
  });

  testWidgets('kayitli lastigi olmayan konumda Degistir degisim penceresi acar',
      (WidgetTester tester) async {
    final (AppState state, TireChangeProvider _) =
        await pumpScreen(tester, const Size(1280, 800));

    await tester.tap(find.text('Değiştir').first);
    await tester.pumpAndSettle();
    expect(find.text('Değişimi Kaydet'), findsOneWidget);
    expect(find.text('İlk Lastik Kaydını Kaydet'), findsNothing);
    expect(find.text('Sökülecek lastik'), findsNothing);

    await fill(tester, 'SN-9', '100', 'Michelin', coated: true);
    await tester.tap(find.text('Değişimi Kaydet'));
    await tester.pumpAndSettle();

    final Map<String, Object?> payload = state.pendingOf(PendingKind.tire).single.payload;
    expect(payload['op'], 'degisim');
    expect(payload['coating'], 1);
    expect(payload.containsKey('previousSerialNo'), isFalse);
  });

  testWidgets('pencere kucuk tablet ekraninda tasmaz', (WidgetTester tester) async {
    await pumpScreen(tester, const Size(1024, 600));
    await tester.tap(find.text('İlk lastik kaydı').first);
    await tester.pumpAndSettle();
    expect(find.text('İlk Lastik Kaydını Kaydet'), findsOneWidget);
    // Pencerenin en altındaki butona kaydırarak ulaşılabilir.
    await tester.ensureVisible(find.text('Hayır'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

