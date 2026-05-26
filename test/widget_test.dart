import 'package:flutter_test/flutter_test.dart';
import 'package:prosacco_mobile/main.dart';

void main() {
  testWidgets('ProSacco app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProSaccoMobileApp());
    expect(find.text('ProSacco'), findsOneWidget);
  });
}
