import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ontarioedai/main.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Axiom Education initial load test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('Axiom Education — Ontario Pack'), findsOneWidget);
  });
}
