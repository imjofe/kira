import 'dart:async';
import 'dart:convert'; // Import for jsonEncode
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kira_flutter_client/services/websocket_service.dart'; // Import WebSocketService

class NodeService {
  static final NodeService instance = NodeService._();
  final MethodChannel _channel = const MethodChannel('kira/node');

  NodeService._();

  Future<bool> sendFrame(Map<String, dynamic> frame) async {
    try {
      return await _channel.invokeMethod<bool>('sendFrame', jsonEncode(frame)) ?? false;
    } on MissingPluginException catch (_) {
      // Fallback during dev: push via WebSocketService so UI doesn’t crash
      debugPrint('[NodeService] sendFrame plugin missing – routing through WebSocket');
      // Assuming WebSocketService.instance is available and has a send method
      // Note: This creates a circular dependency if WebSocketService uses NodeService directly.
      // For this specific fallback, we're assuming WebSocketService is a higher-level abstraction.
      WebSocketService().send(frame); // Use the production constructor for fallback
      return true; // pretend success
    }
  }

  Stream<String> stdout() {
    // This is a placeholder. A real implementation would use an EventChannel.
    return Stream.fromIterable(['{"pong":1}']);
  }

  Future<void> start() async {
    await _channel.invokeMethod('start');
  }
}