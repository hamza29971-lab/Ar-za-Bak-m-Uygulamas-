import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/theme/app_theme.dart';
import 'package:nimo_arizabakim/widgets/kiosk_exit_gate.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Center(child: KioskPasswordDialog())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sayi paneli tablet yatay ekranda tasmadan siger',
      (WidgetTester tester) async {
    await pumpDialog(tester, size: const Size(1280, 800));

    for (final String key in <String>['1', '5', '9', '0']) {
      expect(find.text(key), findsOneWidget);
    }
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);
    expect(find.text('Yetkili Girişi'), findsOneWidget);
  });

  testWidgets('kucuk yatay ekranda da tasma yok', (WidgetTester tester) async {
    await pumpDialog(tester, size: const Size(1024, 600));
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('sistem klavyesi acan bir alan yok', (WidgetTester tester) async {
    await pumpDialog(tester, size: const Size(1280, 800));
    // TextField olsaydi tablette sistem klavyesi acilirdi.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('basilan haneler nokta gostergesini doldurur',
      (WidgetTester tester) async {
    await pumpDialog(tester, size: const Size(1280, 800));

    int filledDots() {
      final Iterable<AnimatedContainer> dots =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      return dots
          .where((AnimatedContainer d) =>
              (d.decoration as BoxDecoration?)?.color != Colors.transparent)
          .length;
    }

    expect(filledDots(), 0);

    await tester.tap(find.text('4'));
    await tester.pump();
    expect(filledDots(), 1);

    await tester.tap(find.text('7'));
    await tester.pump();
    expect(filledDots(), 2);

    // Geri tusu son haneyi siler.
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(filledDots(), 1);

    // Temizle tusu hepsini siler.
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(filledDots(), 0);
  });
}
