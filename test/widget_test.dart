import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parking_br/screens/check_in_page.dart';

void main() {
  testWidgets('formulário bloqueia entrada com placa inválida', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CheckInPage()));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Placa'),
      'ABC12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar entrada'));
    await tester.pump();

    expect(find.text('Informe uma placa válida'), findsOneWidget);
  });

  testWidgets('formulário suporta tela estreita e texto ampliado', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: CheckInPage(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
