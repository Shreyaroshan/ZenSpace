import 'package:flutter_test/flutter_test.dart';
import 'package:zenspace/main.dart';

void main() {
  testWidgets('App loads and shows onboarding', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We pass showOnboarding: true to ensure it starts at the beginning.
    await tester.pumpWidget(const ZenSpaceApp(showOnboarding: true));

    // Verify that onboarding text is present.
    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.textContaining('ZenSpace'), findsOneWidget);
  });
}
