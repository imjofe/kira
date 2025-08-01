import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LLM inference test', (WidgetTester tester) async {
    final result = await Gemma3n.run('2+2=');
    expect(result, 4);
  });
}
