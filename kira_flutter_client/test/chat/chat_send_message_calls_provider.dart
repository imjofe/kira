import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/chat/chat_screen.dart';
import 'package:kira_flutter_client/features/chat/widgets/chat_input_bar.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'chat_send_message_calls_provider.mocks.dart';

@GenerateMocks([ChatProvider])
void main() {
  testWidgets('chat input bar calls provider send method', (tester) async {
    // Create mock provider
    final mockProvider = MockChatProvider();
    when(mockProvider.messages).thenReturn([]);
    when(mockProvider.isLoading).thenReturn(false);
    when(mockProvider.isTyping).thenReturn(false);

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Container(
            decoration: const BoxDecoration(gradient: skyDawnGradient),
            child: const ChatScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the text field and enter text
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    
    await tester.enterText(textField, 'Hi');
    await tester.pump();

    // Find and tap the send button
    final sendButton = find.byIcon(Icons.send);
    expect(sendButton, findsOneWidget);
    
    await tester.tap(sendButton);
    await tester.pump();

    // Verify that send was called with the correct message
    verify(mockProvider.send('Hi')).called(1);
  });

  testWidgets('chat input bar sends message on enter key', (tester) async {
    // Create mock provider
    final mockProvider = MockChatProvider();
    when(mockProvider.messages).thenReturn([]);
    when(mockProvider.isLoading).thenReturn(false);
    when(mockProvider.isTyping).thenReturn(false);

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Container(
            decoration: const BoxDecoration(gradient: skyDawnGradient),
            child: const ChatScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the text field and enter text
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    
    await tester.enterText(textField, 'Hello world');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    // Verify that send was called with the correct message
    verify(mockProvider.send('Hello world')).called(1);
  });
}