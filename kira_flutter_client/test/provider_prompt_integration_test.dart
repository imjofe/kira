import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/services/websocket_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kira_flutter_client/ui/chat/message_dto.dart';

class MockLlamaBridge extends Mock implements LlamaBridge {}

class MockWebSocketService extends Mock implements WebSocketService {
  @override
  Stream<Map<String, dynamic>> get stream => Stream.value({});

  @override
  Future<List<MessageDto>> getLastMessages({int limit = 10}) async => [];
}

void main() {
  test('ChatProvider uses PromptBuilder layers correctly', () async {
    final mockLlamaBridge = MockLlamaBridge();
    final chatProvider = ChatProvider(ws: MockWebSocketService(), gemma: mockLlamaBridge);
    final envJsonString = await chatProvider.debugBuildPrompt('Hi');
    final env = jsonDecode(envJsonString);
    expect(env['messages'][0]['content'].toString().startsWith('You are Kira-Gemma'), isTrue);
    expect(env['messages'][1]['content'].toString().contains('<<MODULE:CHAT>>'), isTrue);
  });
}