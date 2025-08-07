import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/services/websocket_service.dart';

void main() {
  test('WebSocketService.fake sends and receives a frame', () {
    final ctrl = StreamController<Map<String, dynamic>>();
    final ws = WebSocketService.fake(ctrl);
    ws.send({'type': 'ping'});
    expectLater(ws.stream, emits({'type': 'ping'}));
  });
}
