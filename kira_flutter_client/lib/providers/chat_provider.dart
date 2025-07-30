'''import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/session.dart';
import '../models/task.dart';
import '../services/db_service.dart';
import '../services/ws_service.dart';

class ChatProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final List<types.Message> _messages = [];
  List<types.Message> get messages => List.unmodifiable(_messages);

  late final WsService _ws;
  late final DbService _db;

  ChatProvider() {
    _ws = WsService();
    _db = DbService();
    _ws.connect(onMessage: _handleWsFrame);
    _addBotWelcome();
  }

  void sendUserText(String text) {
    final msg = types.TextMessage(
      id: _uuid.v4(),
      author: const types.User(id: 'local_user'),
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _messages.insert(0, msg);
    notifyListeners();
    _ws.sendUserText(text);
  }

  void _handleWsFrame(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'server_typing_indicator':
        // TODO: show typing bubbles (optional)
        break;
      case 'server_sends_response':
        final data = json['data'] as Map<String, dynamic>;
        final txt = data['text'] as String? ?? '';
        final msg = types.TextMessage(
          id: json['trace_id'] ?? _uuid.v4(),
          author: const types.User(id: 'kira_bot'),
          text: txt,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        _messages.insert(0, msg);

        if (data.containsKey('goal')) {
          final goal = Goal.fromMap(data['goal'] as Map<String, Object?>);
          _db.insertGoal(goal);
        }

        if (data.containsKey('tasks')) {
          final tasks = (data['tasks'] as List)
              .map((taskJson) => Task.fromMap(taskJson as Map<String, Object?>))
              .toList();
          _db.insertTasks(tasks);
        }

        if (data.containsKey('events')) {
          final sessions = (data['events'] as List)
              .map((eventJson) =>
                  Session.fromMap(eventJson as Map<String, Object?>))
              .toList();
          _db.insertSessions(sessions);
        }

        notifyListeners();
        break;
    }
  }

  void _addBotWelcome() {
    _messages.add(
      types.TextMessage(
        id: 'welcome-1',
        author: const types.User(id: 'kira_bot'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        text: " Hello! I'm Kira. What's a goal you have in mind today?",
      ),
    );
  }

  @override
  void dispose() {
    _ws.dispose();
    super.dispose();
  }
}''
