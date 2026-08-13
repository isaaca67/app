import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stitch_cov_dark_mobile_login/screens/home_screen.dart';

void main() {
  testWidgets('task editor validates and returns a draft', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TaskEditorDialog())),
    );

    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Escribe un título.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Preparar entrega',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva tarea'), findsNothing);
  });
}
