import 'package:flutter_test/flutter_test.dart';
import 'package:domuscast/main.dart';

void main() {
  testWidgets('DomusCastApp smoke test — renders landing screen', (tester) async {
    await tester.pumpWidget(const DomusCastApp());

    // Landing screen must show the brand name and the enter button
    expect(find.text('DomusCast'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
