import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/theme/app_theme.dart';
import 'package:nimo_arizabakim/ui/screens/login_screen.dart';
import 'package:nimo_arizabakim/widgets/numeric_keypad.dart';

void main() {
  group('formatPhoneDigits', () {
    test('bos giris bos doner', () {
      expect(formatPhoneDigits(''), '');
    });

    test('alan kodu tamamlaninca parantez kapanir', () {
      expect(formatPhoneDigits('053'), '(053');
      expect(formatPhoneDigits('0532'), '(0532) ');
      expect(formatPhoneDigits('05321'), '(0532) 1');
    });

    test('tam numara bosluklarla ayrilir', () {
      expect(formatPhoneDigits('05321234567'), '(0532) 123 45 67');
    });

    test('ara uzunluklar da bicimlenir', () {
      expect(formatPhoneDigits('0532123'), '(0532) 123');
      expect(formatPhoneDigits('053212345'), '(0532) 123 45');
    });
  });

  group('NumericKeypad', () {
    Future<void> pump(
      WidgetTester tester, {
      required Widget keypad,
      Size size = const Size(1280, 800),
      double width = 500,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(child: SizedBox(width: width, child: keypad)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tuslar dogru degerleri bildirir', (WidgetTester tester) async {
      final List<String> pressed = <String>[];
      int backspaces = 0;
      int clears = 0;
      int dones = 0;

      await pump(
        tester,
        keypad: NumericKeypad(
          stretch: true,
          onDigit: pressed.add,
          onBackspace: () => backspaces++,
          onClear: () => clears++,
          onDone: () => dones++,
        ),
      );

      for (final String key in <String>['0', '5', '3', '2']) {
        await tester.tap(find.text(key));
        await tester.pump();
      }
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.tap(find.byIcon(Icons.clear));
      await tester.tap(find.text('Tamam'));
      await tester.pump();

      expect(pressed, <String>['0', '5', '3', '2']);
      expect(backspaces, 1);
      expect(clears, 1);
      expect(dones, 1);
    });

    testWidgets('giris sutunu genisliginde tasma yok',
        (WidgetTester tester) async {
      // Giris formu 460-760 arasi; ic genislik 44px dolgu dusulunce ~372.
      await pump(
        tester,
        width: 372,
        keypad: NumericKeypad(
          stretch: true,
          keyHeight: 54,
          onDigit: (_) {},
          onBackspace: () {},
          onClear: () {},
          onDone: () {},
        ),
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Tamam'), findsOneWidget);
    });

    testWidgets('onay tusu verilmezse gosterilmez',
        (WidgetTester tester) async {
      await pump(
        tester,
        keypad: NumericKeypad(
          onDigit: (_) {},
          onBackspace: () {},
          onClear: () {},
        ),
      );
      expect(find.text('Tamam'), findsNothing);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('tuslar odagi calmaz', (WidgetTester tester) async {
      // Odak metin alanindan kacarsa panel kendini kapatirdi.
      await pump(
        tester,
        keypad: NumericKeypad(
          onDigit: (_) {},
          onBackspace: () {},
        ),
      );
      final Iterable<InkWell> keys = tester.widgetList<InkWell>(
        find.descendant(
          of: find.byType(NumericKeypad),
          matching: find.byType(InkWell),
        ),
      );
      expect(keys, isNotEmpty);
      for (final InkWell key in keys) {
        expect(key.canRequestFocus, isFalse);
      }
    });
  });
}
