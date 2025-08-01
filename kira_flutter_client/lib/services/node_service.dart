import 'package:flutter/services.dart';

class NodeService {
  static final NodeService instance = NodeService._();
  final MethodChannel _channel = const MethodChannel('kira/node');

  NodeService._();

  Future<void> sendFrame(Map<String, dynamic> frame) =>
      _channel.invokeMethod('sendFrame', frame);

  Stream<String> stdout() {
    // This is a placeholder. A real implementation would use an EventChannel.
    return Stream.fromIterable(['{"pong":1}']);
  }

  Future<void> start() async {
    await _channel.invokeMethod('start');
  }
}
