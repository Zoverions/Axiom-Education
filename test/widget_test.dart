import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ontarioedai/main.dart';

void main() {
  // Initialize sqflite_ffi for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('OntarioEdAI initial load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that the title text is found.
    expect(find.text('Curriculum Diagnostic Overview'), findsOneWidget);
  });
}
