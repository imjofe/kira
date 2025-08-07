import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/services/websocket_service.dart';
import 'package:kira_flutter_client/ui/chat/chat_page.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/ui/chat/message_dto.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

class MockLlamaBridge extends Mock implements LlamaBridge {}

void main() {
  group('ChatPage', () {
    late MockWebSocketService mockWs;
    late MockLlamaBridge mockGemma;
    late ChatProvider chatProvider;

    setUp(() {
      mockWs = MockWebSocketService();
      mockGemma = MockLlamaBridge();
      // Stub the stream getter to return an empty stream initially
      when(() => mockWs.stream).thenAnswer((_) => Stream.empty());
      // Stub the send method
      when(() => mockWs.send(any())).thenAnswer((_) async {});

      chatProvider = ChatProvider.fake(ws: mockWs, gemma: mockGemma);
    });

    testWidgets('ChatPage renders and send button works', (tester) async {
      // Arrange: Seed provider with two messages
      chatProvider.messages.addAll([
        MessageDto.user('hello'),
        MessageDto.assistant('world'),
      ]);

      // Mock the platform channel for NodeService (used by ChatProvider)
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('kira/node'),
        (MethodCall methodCall) async => null,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatProvider>.value(
          value: chatProvider,
          child: const MaterialApp(
            home: ChatPage(testing: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert initial find
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('world'), findsOneWidget);

      // Act: Enter text "ping" and tap send
      await tester.enterText(find.byType(TextField), 'ping');
      await tester.tap(find.byType(IconButton));
      await tester.pump(); // Allow optimistic update

      // Assert: Optimistic user bubble appears
      expect(find.text('ping'), findsOneWidget);

      // Mock Gemma response for the 'ping' message
      when(() => mockGemma.run(prompt: any(named: 'prompt')))
          .thenAnswer((_) => Stream.value('pong'));

      // Trigger the async work for Gemma response
      await tester.runAsync(() async {
        await chatProvider.send('ping');
      });
      await tester.pumpAndSettle();

      // Assert: New assistant bubble appears
      expect(find.text('pong'), findsOneWidget);
    });
  });
}