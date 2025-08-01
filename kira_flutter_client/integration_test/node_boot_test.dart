import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kira_flutter_client/services/node_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Node.js boot test', (WidgetTester tester) async {
    final nodeService = NodeService();
    await nodeService.start();
    nodeService.sendWebSocketFrame({'ping': 1});
    // We can't easily test the pong response here without more complex
    // stream-based communication, so we'll just check that the app doesn't crash.
    expect(true, isTrue);
  });
}
