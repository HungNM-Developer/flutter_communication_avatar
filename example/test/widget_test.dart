import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_communication_avatar_example/main.dart';

void main() {
  testWidgets('Verify Communication Avatar Example App renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CommunicationAvatarExampleApp());

    // Verify title text is displayed.
    expect(find.text('Communication Avatar Demo'), findsOneWidget);
  });
}
