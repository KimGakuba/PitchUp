import 'package:flutter_test/flutter_test.dart';

import 'package:pitchup/app.dart';

void main() {
  testWidgets('shows a startup error when Firebase fails to initialize', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PitchUpApp(initError: 'emulator offline'));
    await tester.pumpAndSettle();

    expect(find.text('Could not start PitchUp'), findsOneWidget);
    expect(find.text('emulator offline'), findsOneWidget);
  });
}
