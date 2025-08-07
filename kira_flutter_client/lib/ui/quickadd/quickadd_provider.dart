import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/utils/prompt_builder.dart';
import 'package:kira_flutter_client/utils/slash_router.dart';
import 'package:kira_flutter_client/ui/schedule/quick_add_sheet.dart';

class QuickAddProvider {
  QuickAddProvider({required this.gemma});
  final LlamaBridge gemma;

  static void openModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const QuickAddSheet(),
    );
  }

  Stream<String> quickAdd(String userInput) {
    final l1 = '<<MODULE:QuickAdd>> Return a single **JSON TaskCreate** with `title` (≤6 words) & `duration` (int, minutes). No commentary.';
    final env = PromptBuilder.build(
      l1Persona: l1,
      userInput: userInput,
      requireJson: true,
      l3Ephemeral: SlashRouter.content(SlashCommand.modeJson),
    );
    return gemma.run(prompt: jsonEncode(env));
  }
}