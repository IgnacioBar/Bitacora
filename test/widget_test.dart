import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pescatronik/main.dart';

void main() {
  testWidgets('abre el diario desde la portada', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DiaryCoverScreen()));

    expect(find.text('Abrir diario'), findsNothing);
    expect(find.text('Toca la pantalla para abrir el diario'), findsOneWidget);

    await tester.tap(find.text('Toca la pantalla para abrir el diario'));
    await tester.pumpAndSettle();

    expect(find.text('España'), findsOneWidget);
  });

  testWidgets('muestra España como país inicial', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CountryScreen()));

    expect(find.text('Pescatronik'), findsOneWidget);
    expect(find.text('España'), findsOneWidget);
  });
}
