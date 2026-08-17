import 'package:flutter_test/flutter_test.dart';
import 'package:nimo_arizabakim/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NimoApp());
    expect(find.text('Lastik Değişimi'), findsOneWidget);
  });
}
