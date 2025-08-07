import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/chat/chat_screen.dart';
import 'package:kira_flutter_client/features/chat/widgets/dots_typing.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/ui/chat/message_dto.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'chat_typing_indicator_visible.mocks.dart';

@GenerateMocks([ChatProvider])
void main() {
  testWidgets('typing indicator is visible when provider isTyping is true', (tester) async {
    // Create mock provider with isTyping = true
    final mockProvider = MockChatProvider();
    final messages = [
      MessageDto.user('Hello'),
    ];

    when(mockProvider.messages).thenReturn(messages);
    when(mockProvider.isLoading).thenReturn(false);
    when(mockProvider.isTyping).thenReturn(true);

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

    await tester.pump();

    // Verify that DotsTyping widget is visible
    expect(find.byType(DotsTyping), findsOneWidget);
  });

  testWidgets('typing indicator is not visible when provider isTyping is false', (tester) async {
    // Create mock provider with isTyping = false
    final mockProvider = MockChatProvider();
    final messages = [
      MessageDto.user('Hello'),
    ];

    when(mockProvider.messages).thenReturn(messages);
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

    await tester.pump();

    // Verify that DotsTyping widget is not visible
    expect(find.byType(DotsTyping), findsNothing);
  });
}