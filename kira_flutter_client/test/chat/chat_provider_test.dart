// FIXED: correct imports + named‐param stubs
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/services/websocket_service.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/ui/chat/message_dto.dart';

class MockWebSocketService extends Mock implements WebSocketService {
  @override
  Stream<Map<String, dynamic>> get stream => Stream.empty();
  
  @override
  Future<List<MessageDto>> getLastMessages({int limit = 10}) async => [];
}
class MockLlamaBridge extends Mock implements LlamaBridge {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse("ws://localhost:8080"));
  });

  group('ChatProvider', () {
    late ChatProvider chatProvider;
    late MockWebSocketService mockWebSocketService;
    late MockLlamaBridge mockLlamaBridge;

    setUp(() {
      mockWebSocketService = MockWebSocketService();
      mockLlamaBridge = MockLlamaBridge();
      chatProvider = ChatProvider(
        gemma: mockLlamaBridge,
        ws: mockWebSocketService,
      );
    });

    test('send sends message to websocket when it starts with a slash', () async {
      when(() => mockWebSocketService.send(any())).thenAnswer((_) async {});

      await chatProvider.send('/test');

      verify(() => mockWebSocketService.send(any())).called(1);
      verifyNever(() => mockLlamaBridge.run(prompt: any(named: 'prompt')));
    });

    test('send sends message to llama when it does not start with a slash', () async {
      when(() => mockLlamaBridge.run(prompt: any(named: 'prompt')))
          .thenAnswer((_) => Stream.fromIterable(['hello', ' world']));

      await chatProvider.send('hello');

      verify(() => mockLlamaBridge.run(prompt: any(named: 'prompt'))).called(1);
      verifyNever(() => mockWebSocketService.send(any()));
    });
  });
}