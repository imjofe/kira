import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
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

  testWidgets('User message appears in UI after sending', (tester) async {
    await tester.pumpWidget(const KiraApp());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'My test goal');
    await tester.pumpAndSettle();

    final sendButton = find.byType(SendButton);
    expect(sendButton, findsOneWidget);

    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('My test goal'), findsOneWidget);
  });
}
