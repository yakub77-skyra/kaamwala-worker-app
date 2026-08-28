import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala_partner/bootstrap.dart';

void main() {
  testWidgets('App boots to splash then navigates', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KaamWalaPartnerApp()));

    // Splash is showing brand name.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('KaamWala Partner'), findsOneWidget);

    // Fire the splash delay + session restore + router redirect.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(seconds: 1));
    // Demo mode (no backend configured) lands on the worker shell.
    expect(find.text('Home'), findsWidgets);
  });
}