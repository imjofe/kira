import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/main.dart';
import 'package:kira_flutter_client/services/ws_service.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  tearDown(() {
    WsService.resetSingleton();
  });

  testWidgets('Chat UI loads with welcome message', (tester) async {
    await tester.pumpWidget(const KiraApp());
    await tester.pumpAndSettle();
    expect(find.textContaining("What's a goal you have in mind today?"), findsOneWidget);
  });
}
