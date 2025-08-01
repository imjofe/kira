import 'package:flutter/services.dart';

class NodeService {
  static final NodeService instance = NodeService._();

  NodeService._();

  Future<void> start() async =>
    const MethodChannel('kira/node').invokeMethod('start', [
      'node',
      '/data/data/com.example.kira_flutter_client/files/flutter_assets/assets/node/server.js'
    ]);

  Stream<String> stdout() {
    // TODO: Implement stdout stream
    return Stream.value('{"pong":1}');
  }
}