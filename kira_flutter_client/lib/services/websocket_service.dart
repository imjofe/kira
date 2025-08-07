import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kira_flutter_client/services/node_service.dart';
import 'package:kira_flutter_client/ui/chat/message_dto.dart';

/// A test-friendly wrapper around the NodeService MethodChannel for WebSocket communication.
class WebSocketService {
  final StreamController<Map<String, dynamic>>? _fakeController;
  late final Stream<Map<String, dynamic>> _stream;

  /// Production constructor that uses the real NodeService.
  WebSocketService() : _fakeController = null {
    // In a real implementation, NodeService would expose a broadcast stream.
    // For now, we'll use a placeholder that can be replaced later.
    // _stream = NodeService.instance.frameStream;
    // Placeholder until frameStream is implemented:
    _stream = Stream<Map<String, dynamic>>.empty().asBroadcastStream();
    debugPrint('WebSocketService: Using real NodeService');
  }

  /// Test constructor that uses a fake StreamController for testing.
  WebSocketService.fake(StreamController<Map<String, dynamic>> controller)
      : _fakeController = controller {
    _stream = _fakeController!.stream;
    debugPrint('WebSocketService: Using fake StreamController');
  }

  /// A stream of inbound frames from the WebSocket.
  Stream<Map<String, dynamic>> get stream => _stream;

  /// Sends an outbound frame over the WebSocket.
  void send(Map<String, dynamic> frame) {
    if (_fakeController != null) {
      debugPrint('[FAKE] Sending frame: $frame');
      _fakeController.sink.add(frame);
    } else {
      debugPrint('[PROD] Sending frame: $frame');
      NodeService.instance.sendFrame(frame);
    }
  }

  /// Closes the underlying resources.
  /// In fake mode, this closes the injected StreamController.
  Future<void> dispose() async {
    if (_fakeController != null) {
      debugPrint('WebSocketService: Disposing fake StreamController');
      await _fakeController!.close();
    }
    // In production, NodeService manages its own lifecycle.
  }

  /// Fetches the last N messages from the backend.
  Future<List<MessageDto>> getLastMessages({int limit = 20}) async {
    // This is a mock implementation for now.
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return [
      MessageDto.assistant('Hello! How can I help you today?'),
      MessageDto.user('Tell me a joke.'),
      MessageDto.assistant('Why did the scarecrow win an award? Because he was outstanding in his field!'),
    ];
  }
}
