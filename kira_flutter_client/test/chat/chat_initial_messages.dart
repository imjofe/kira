import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/chat/chat_screen.dart';
import 'package:kira_flutter_client/features/chat/widgets/chat_bubble.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/ui/chat/message_dto.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'chat_initial_messages.mocks.dart';

@GenerateMocks([ChatProvider])
void main() {
  testWidgets('chat screen shows initial messages with correct alignment', (tester) async {
    // Create mock provider with two messages
    final mockProvider = MockChatProvider();
    final messages = [
      MessageDto.user('Hello, how are you?'),
      MessageDto.assistant('I\'m doing great, thanks for asking!'),
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

    await tester.pumpAndSettle();

    // Verify that both ChatBubble widgets are rendered
    expect(find.byType(ChatBubble), findsNWidgets(2));

    // Check message content
    expect(find.text('Hello, how are you?'), findsOneWidget);
    expect(find.text('I\'m doing great, thanks for asking!'), findsOneWidget);

    // Verify alignment by checking the Align widgets inside ChatBubbles
    final chatBubbles = tester.widgetList<ChatBubble>(find.byType(ChatBubble));
    final chatBubblesList = chatBubbles.toList();
    
    // First message should be from user (right aligned)
    expect(chatBubblesList[0].msg.role, equals('user'));
    expect(chatBubblesList[0].msg.content, equals('Hello, how are you?'));
    
    // Second message should be from assistant (left aligned)
    expect(chatBubblesList[1].msg.role, equals('assistant'));
    expect(chatBubblesList[1].msg.content, equals('I\'m doing great, thanks for asking!'));
  });
}