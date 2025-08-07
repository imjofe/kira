import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:kira_flutter_client/models/task_dto.dart';
import 'package:kira_flutter_client/models/session_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart'; // For AsyncValue
import 'package:kira_flutter_client/services/node_service.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_api.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/utils/prompt_builder.dart';
import 'package:kira_flutter_client/utils/slash_router.dart';

import 'dart:convert';

class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider({this.testSeed, required this.gemma});
  final List<TaskDto>? testSeed;
  final LlamaBridge gemma;

  final _today = <TaskDto>[];
  UnmodifiableListView<TaskDto> get tasks => UnmodifiableListView(_today);

  // Calendar-specific session data
  final Map<String, AsyncValue<List<SessionModel>>> _sessionsByDate = {};
  List<SessionModel>? _seedSessions;

  Future<void> fetchToday() async {
    if (testSeed != null) {
      _today
        ..clear()
        ..addAll(testSeed!);
      notifyListeners();
      return;
    }
    _today
      ..clear()
      ..addAll(await ScheduleApi.getToday());
    notifyListeners();
  }

  Future<void> updateStatus(int id, String status) async {
    final i = _today.indexWhere((t) => t.id == id);
    if (i != -1) {
      _today[i] = _today[i].copyWith(status: status);
      notifyListeners();
    }
    // fire-and-forget
    unawaited(NodeService.instance.sendFrame({
      'type': 'task.update',
      'payload': {'id': id, 'status': status}
    }));
  }

  // Calendar functionality
  AsyncValue<List<SessionModel>> watchSessionsForDate(DateTime date) {
    final dateKey = _dateKey(date);
    
    // Return cached result if available
    if (_sessionsByDate.containsKey(dateKey)) {
      return _sessionsByDate[dateKey]!;
    }

    // Start loading sessions for this date
    _loadSessionsForDate(date);
    return const AsyncValue.loading();
  }

  Future<void> _loadSessionsForDate(DateTime date) async {
    final dateKey = _dateKey(date);
    _sessionsByDate[dateKey] = const AsyncValue.loading();
    notifyListeners();

    try {
      // Only add delay if not in test mode
      if (!_isInTestMode()) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Generate mock sessions for this date
      final sessions = _generateSessionsForDate(date);
      _sessionsByDate[dateKey] = AsyncValue.data(sessions);
    } catch (e) {
      _sessionsByDate[dateKey] = AsyncValue.error(e);
    }
    
    notifyListeners();
  }

  List<SessionModel> _generateSessionsForDate(DateTime date) {
    // Use seed sessions if available for testing
    if (_seedSessions != null) {
      return _seedSessions!.where((session) {
        return session.startTime.year == date.year &&
               session.startTime.month == date.month &&
               session.startTime.day == date.day;
      }).toList();
    }

    // Generate mock sessions based on date for demo purposes
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
    
    if (isToday || isFuture) {
      return [
        SessionModel(
          id: date.day * 1000 + 1,
          title: 'Morning Workout',
          startTime: DateTime(date.year, date.month, date.day, 7, 0),
          endTime: DateTime(date.year, date.month, date.day, 8, 0),
          status: isToday ? SessionStatus.pending : SessionStatus.pending,
        ),
        SessionModel(
          id: date.day * 1000 + 2,
          title: 'Focus Time',
          startTime: DateTime(date.year, date.month, date.day, 10, 0),
          endTime: DateTime(date.year, date.month, date.day, 11, 30),
          status: isToday ? SessionStatus.pending : SessionStatus.pending,
        ),
        if (date.weekday <= 5) // Only on weekdays
          SessionModel(
            id: date.day * 1000 + 3,
            title: 'Evening Review',
            startTime: DateTime(date.year, date.month, date.day, 18, 0),
            endTime: DateTime(date.year, date.month, date.day, 18, 30),
            status: isToday ? SessionStatus.pending : SessionStatus.pending,
          ),
      ];
    }
    
    return []; // No sessions for past dates (except today)
  }

  Future<void> completeSession(int sessionId) async {
    // Find and update the session in all cached dates
    for (final entry in _sessionsByDate.entries) {
      final sessions = entry.value.data;
      if (sessions != null) {
        final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
        if (sessionIndex != -1) {
          // Update the session status
          final updatedSessions = List<SessionModel>.from(sessions);
          updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(
            status: SessionStatus.completed,
          );
          
          // Update the cache
          _sessionsByDate[entry.key] = AsyncValue.data(updatedSessions);
          notifyListeners();
          
          // Simulate persistence (would normally call database)
          if (!_isInTestMode()) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
          break;
        }
      }
    }
  }

  // For testing - initialize with specific sessions
  void initWithSeedSessions(List<SessionModel> sessions) {
    _seedSessions = sessions;
    // Clear existing cache to force reload with new seed data
    _sessionsByDate.clear();
    notifyListeners();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isInTestMode() {
    // Simple check for test environment
    bool inTestMode = false;
    assert(() {
      inTestMode = true;
      return true;
    }());
    return inTestMode;
  }

  Stream<String> runSchedule(String userInput, {bool asJson = false}) {
    final l1 = '<<MODULE:SCHED>> You are Kira\'s **schedule agent**. Convert natural-language snippets into `{title,start,duration}` respecting local timezone America/Mexico_City.';
    final env = PromptBuilder.build(
      l1Persona: l1,
      userInput: userInput,
      requireJson: asJson,
      l3Ephemeral: asJson ? SlashRouter.content(SlashCommand.modeJson) : null,
    );
    return gemma.run(prompt: jsonEncode(env));
  }
}
