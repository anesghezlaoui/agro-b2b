import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrob2b/app.dart';

void main() {
  testWidgets('AgroB2B démarre (smoke)', (WidgetTester tester) async {
    await tester.pumpWidget(const AgroB2BApp());
    await tester.pump();
    // Laisse le temps à AuthProvider.init() (sans pumpAndSettle : indicateur de chargement anime en boucle).
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
