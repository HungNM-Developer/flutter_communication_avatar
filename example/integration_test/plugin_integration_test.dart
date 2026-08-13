import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_communication_avatar/flutter_communication_avatar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hasPermissions check test', (WidgetTester tester) async {
    final bool hasPermission = await FlutterCommunicationAvatar.instance.hasPermissions();
    expect(hasPermission, isA<bool>());
  });
}
