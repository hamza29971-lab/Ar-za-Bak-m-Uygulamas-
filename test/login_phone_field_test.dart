import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/theme/app_theme.dart';
import 'package:nimo_arizabakim/ui/screens/login_screen.dart';
import 'package:nimo_arizabakim/widgets/numeric_keypad.dart';

/// Telefon alanindaki TextField'i bulur (sifre alani da ayni ekranda).
Finder phoneField() => find.byWidgetPredicate(
      (Widget w) =>
          w is TextField &&
          w.decoration?.hintText == '(05XX) XXX XX XX',
    );

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LoginScreen(),
      ),
    );
    // Giris animasyonu 1200 ms.
    await tester.pump(const Duration(milliseconds: 1400));
  }

  testWidgets('telefon alani sistem klavyesini acmaz',
      (WidgetTester tester) async {
    await pumpLogin(tester);

    final TextField field = tester.widget<TextField>(phoneField());
    // readOnly true iken Flutter yazilim klavyesini hic istemez.
    expect(field.readOnly, isTrue);
    // Imlec yine gorunmeli ki alan devre disi sanilmasin.
    expect(field.showCursor, isTrue);
  });

  testWidgets('alana dokununca uygulama ici sayi paneli acilir',
      (WidgetTester tester) async {
    await pumpLogin(tester);

    expect(find.byType(NumericKeypad), findsNothing);

    await tester.tap(phoneField());
    await tester.pumpAndSettle();

    expect(find.byType(NumericKeypad), findsOneWidget);
  });

  testWidgets('panelden girilen rakamlar telefon bicimine donusur',
      (WidgetTester tester) async {
    await pumpLogin(tester);
    await tester.tap(phoneField());
    await tester.pumpAndSettle();

    for (final String digit in <String>['0', '5', '3', '2', '1', '2', '3']) {
      await tester.tap(find.text(digit).last);
      await tester.pump();
    }

    expect(tester.widget<TextField>(phoneField()).controller?.text,
        '(0532) 123');

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(tester.widget<TextField>(phoneField()).controller?.text,
        '(0532) 12');

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(tester.widget<TextField>(phoneField()).controller?.text, '');
  });

  testWidgets('Tamam tusu paneli kapatir', (WidgetTester tester) async {
    await pumpLogin(tester);
    await tester.tap(phoneField());
    await tester.pumpAndSettle();
    expect(find.byType(NumericKeypad), findsOneWidget);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(find.byType(NumericKeypad), findsNothing);
  });
}
