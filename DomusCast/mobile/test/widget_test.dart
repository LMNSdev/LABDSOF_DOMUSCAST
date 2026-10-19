import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:domuscast/main.dart';
import 'package:domuscast/screens/reportes_list_screen.dart';

void main() {
  testWidgets('DomusCastApp smoke test - renders landing screen', (tester) async {
    await tester.pumpWidget(const DomusCastApp());

    // Landing screen must show the brand name and the enter button
    expect(find.text('DomusCast'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('ReportesListScreen - AppBar "Reportes" + loading spinner', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportesListScreen()));

    expect(find.text('Reportes'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
