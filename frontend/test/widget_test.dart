// Teste de fumaca do layout principal do LicitHub
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('monta o layout principal com a sidebar', (WidgetTester tester) async {
    await tester.pumpWidget(const LicitHubApp());
    await tester.pump();

    expect(find.text('LicitHub'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Buscar Editais'), findsOneWidget);
    expect(find.text('Funil'), findsOneWidget);
    expect(find.text('Documentos'), findsOneWidget);
  });
}
