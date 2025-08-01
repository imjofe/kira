import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/services/node_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Node.js ping test', (tester) async {
    await NodeService.instance.start();
    final msg = await NodeService.instance.stdout()
        .firstWhere((l) => l.contains('"pong":1'));
    expect(msg, contains('"pong":1'));
  });
}