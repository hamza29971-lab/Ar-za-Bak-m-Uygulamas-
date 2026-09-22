import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/models/models.dart';
import 'package:nimo_arizabakim/state/app_state.dart';
import 'package:nimo_arizabakim/widgets/vehicle_selector.dart';
import 'package:nimo_arizabakim/widgets/vehicle_type_filter.dart';

/// Araç seçicideki tip filtresi: liste uzadıkça araç bulmayı kolaylaştırır.
void main() {
  Future<void> pumpSelector(WidgetTester tester, AppState state) async {
    Vehicle? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          state: state,
          child: Scaffold(
            body: Center(
              child: VehicleSelector(
                selected: selected,
                onSelected: (Vehicle? v) => selected = v,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'kategori secilince liste yalnizca o kategorideki araclari gosterir',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpSelector(tester, AppState());

    // Alana dokununca liste ve filtre satiri acilir.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Ayni metin hem cipte hem liste satirlarinin alt basliginda gectigi
    // icin finder filtre satiriyla sinirlandirilir.
    Finder chip(String label) => find.descendant(
          of: find.byType(VehicleTypeFilter),
          matching: find.text(label),
        );

    // Uc geniş kategori cip olarak gorunur: Kamyon, Ekskavatör, Loder.
    for (final String label in <String>['Tümü', 'Kamyon', 'Ekskavatör', 'Loder']) {
      expect(chip(label), findsOneWidget, reason: label);
    }

    // Filtresiz haldeyken listenin basinda Kamyon kategorisindeki Euclid-1 var.
    expect(find.text('Euclid-1'), findsOneWidget);

    // "Kamyon" filtresi yalnizca Euclid/XCMG/Liugong-16..20'yi birakir;
    // paletli (Ekskavatör) ve Loder araclar cikar.
    await tester.tap(chip('Kamyon'));
    await tester.pumpAndSettle();

    expect(find.text('Euclid-3'), findsOneWidget);
    expect(find.text('Hitachi-1200'), findsNothing);

    await tester.tap(chip('Kamyon'));
    await tester.pumpAndSettle();

    // "Ekskavatör" filtresi Shovel'i (Hitachi 1200/1800/1900) de kapsar.
    await tester.tap(chip('Ekskavatör'));
    await tester.pumpAndSettle();

    expect(find.text('Hitachi-1200'), findsOneWidget);
    expect(find.text('Euclid-1'), findsNothing);
    expect(find.text('Liugong-40'), findsNothing); // Loder, Ekskavatör degil.

    // Ayni cipe tekrar basmak filtreyi kaldirir.
    await tester.tap(chip('Ekskavatör'));
    await tester.pumpAndSettle();
    expect(find.text('Euclid-1'), findsOneWidget);
  });
}
