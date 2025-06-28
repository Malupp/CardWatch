import 'package:flutter_test/flutter_test.dart';

import 'package:card_watch/main.dart';

void main() {
  testWidgets('App loads and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('CardWatch'), findsWidgets);
  });
}
