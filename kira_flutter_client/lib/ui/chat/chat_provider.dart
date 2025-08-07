import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kira_flutter_client/services/db_service.dart';
import 'package:kira_flutter_client/services/websocket_service.dart';
import 'package:kira_flutter_client/ui/chat/message_dto.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/utils/prompt_builder.dart';
import 'dart:convert';

class ChatProvider extends ChangeNotifier {
  final WebSocketService ws;
  final LlamaBridge gemma;
  final bool isFake;

  final List<MessageDto> _messages = [];
  List<MessageDto> get messages => _messages;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final StreamSubscription _wsSubscription;

  ChatProvider({required this.ws, required this.gemma}) : isFake = false {
    _wsSubscription = ws.stream.listen(_handleWsEvents);
    _isLoading = true;
    fetchHistory();
  }

  ChatProvider.fake({required this.ws, required this.gemma}) : isFake = true {
    _wsSubscription = ws.stream.listen(_handleWsEvents);
  }

  @override
  void dispose() {
    _wsSubscription.cancel();
    ws.dispose();
    super.dispose();
  }

  Future<void> initCache() async {
    if (isFake) return;
    // final db = await DbService().db;
    // final maps = await db.query('messages', orderBy: 'ts DESC', limit: 50);
    // _messages.addAll(maps.map(MessageDto.fromJson).toList().reversed);
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    try {
      final list = await ws.getLastMessages(limit: 20);
      _messages
        ..clear()
        ..addAll(list);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> send(String text) async {
    final userMessage = MessageDto.user(text);
    _messages.add(userMessage);
    notifyListeners();

    if (!isFake) {
      // final db = await DbService().db;
      // await db.insert('messages', userMessage.toJson());
    }

    if (text.startsWith('/')) {
      _handleSlashCommand(userMessage);
    } else {
      _handleGemmaQuery(userMessage);
    }
  }

  void _handleSlashCommand(MessageDto message) {
    ws.send({
      'type': 'message.new',
      'payload': message.toJson(),
    });
  }

  Future<void> _handleGemmaQuery(MessageDto message) async {
    final assistantMessage = MessageDto.assistant('');
    _messages.add(assistantMessage);
    _isTyping = true;
    notifyListeners();

    runChat(message.content) // returns Stream<String>
        .listen(
          (chunk) {
            _updateAssistantDraft(chunk); // keep concatenating
            notifyListeners();
          },
          onDone: () {
            _finalizeAssistantMessage(); // draft → finished
            notifyListeners();
          },
          onError: (err) {
            _handleGemmaError(err);
            notifyListeners();
          },
        );
  }

  void _updateAssistantDraft(String chunk) {
    final lastMessage = _messages.last;
    if (lastMessage.role == 'assistant') {
      final updatedMessage = lastMessage.copyWith(content: lastMessage.content + chunk);
      _messages[_messages.length - 1] = updatedMessage;
    }
  }

  void _finalizeAssistantMessage() {
    _isTyping = false;
    final finalMessage = _messages.last;

    if (!isFake) {
      // final db = await DbService().db;
      // await db.insert('messages', finalMessage.toJson());
    }

    ws.send({
      'type': 'message.new',
      'payload': finalMessage.toJson(),
    });
  }

  void _handleGemmaError(Object err) {
    if (kDebugMode) {
      print('[GEMMA ERROR] $err');
    }
    if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
      _messages.removeLast();
    }
    final errorMessage = MessageDto.assistant('Sorry, an error occurred.');
    _messages.add(errorMessage);
    _isTyping = false;
  }

  void _handleWsEvents(Map<String, dynamic> frame) {
    if (kDebugMode) {
      print('[WS] Received frame: $frame');
    }
    switch (frame['type']) {
      case 'server_sends_response':
        final message = MessageDto.fromJson(frame['payload']);
        _messages.add(message);
        if (!isFake) {
          // final db = await DbService().db;
          // await db.insert('messages', message.toJson());
        }
        break;
      case 'server_typing_indicator':
        _isTyping = frame['payload']['on'] as bool;
        break;
    }
    notifyListeners();
  }

  Stream<String> runChat(String userInput) {
    print('[ChatProvider] runChat called with userInput: "$userInput"');
    print('[ChatProvider] gemma instance: $gemma');
    final l1 = '<<MODULE:CHAT>> You are an encouraging **wellness assistant**. Default tone: concise ✨ optimistic.';
    final env = PromptBuilder.build(l1Persona: l1, userInput: userInput);
    print('[ChatProvider] Built prompt envelope, calling gemma.run...');
    try {
      final result = gemma.run(prompt: jsonEncode(env));
      print('[ChatProvider] gemma.run returned successfully');
      return result;
    } catch (e) {
      print('[ChatProvider] ERROR calling gemma.run: $e');
      rethrow;
    }
  }

  Future<String> debugBuildPrompt(String userInput) async {
    final l1 = '<<MODULE:CHAT>> You are an encouraging **wellness assistant**. Default tone: concise ✨ optimistic.';
    final env = PromptBuilder.build(l1Persona: l1, userInput: userInput);
    return jsonEncode(env);
  }
}
