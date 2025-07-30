import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef OnMessage = void Function(Map<String, dynamic> json);

class WsService {
  WsService._();
  static final WsService _singleton = WsService._();
  factory WsService() => _singleton;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  OnMessage? _onMessage;
  bool _isDisposed = false;

  void connect({required OnMessage onMessage}) {
    _isDisposed = false;
    _onMessage = onMessage;
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    final uri = Uri.parse(baseUrl.replaceFirst('http', 'ws') + '/chat');
    _channel = WebSocketChannel.connect(uri);
    _sub = _channel!.stream.listen(
      (data) {
        _onMessage?.call(jsonDecode(data));
      },
      onError: (_) {
        if (!_isDisposed) _reconnect();
      },
      onDone: () {
        if (!_isDisposed) _reconnect();
      },
    );
  }

  void sendUserText(String text) {
    if (_isDisposed) return;
    final frame = {
      "type": "user_sends_message",
      "data": { "text": text }
    };
    _channel?.sink.add(jsonEncode(frame));
  }

  void dispose() {
    _isDisposed = true;
    _sub?.cancel();
    _channel?.sink.close();
  }

  // simple exponential back-off reconnection
  Future<void> _reconnect([int attempt = 1]) async {
    if (_isDisposed) return;
    await Future.delayed(Duration(seconds: attempt.clamp(1, 5)));
    if (_isDisposed) return;
    connect(onMessage: _onMessage!);
  }

  static void resetSingleton() {
    _singleton.dispose();
  }
}