import 'package:flutter/material.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/utils/prompt_builder.dart';
import 'dart:convert';

import 'dart:convert';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider({DateTime? seed, required this.gemma}) : _selected = seed ?? DateTime.now();
  DateTime _selected;
  DateTime get selected => _selected;
  final LlamaBridge gemma;

  void select(DateTime day) {
    _selected = day;
    notifyListeners();
  }

  Stream<String> runCalendar(String userInput) {
    final l1 = '<<MODULE:CAL>> Answer quick questions about date ranges & free slots using the provided `TaskDto[]`.';
    final env = PromptBuilder.build(l1Persona: l1, userInput: userInput);
    return gemma.run(prompt: jsonEncode(env));
  }
}
