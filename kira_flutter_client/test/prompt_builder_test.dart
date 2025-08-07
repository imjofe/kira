import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';
import 'package:kira_flutter_client/utils/prompt_builder.dart';
import 'package:kira_flutter_client/utils/slash_router.dart';
import 'package:kira_flutter_client/core/prompts/global_prompt.dart';

String _golden(String name) => File('test/goldens/$name').readAsStringSync();
String _injectGlobal(String raw) {
  final esc = jsonEncode(kGlobalSystemPrompt).substring(1, jsonEncode(kGlobalSystemPrompt).length - 1);
  return raw.replaceAll('<GLOBAL>', esc);
}

void main() {
  group('PromptBuilder', () {
    test('assembles minimal envelope with metadata', () {
      final env = PromptBuilder.build(
        l1Persona: '<<MODULE:CHAT>> You are Kira\'s chat persona.',
        userInput: 'Hi!',
      );

      expect(env['metadata']['prompt_version'], equals('1.1'));
      expect(env['messages'][0]['content'], equals(kGlobalSystemPrompt));
      expect(env['messages'].where((m) => m['role'] == 'user').first['content'], 'Hi!');
    });

    test('trims memory to 20 items', () {
      final memory = List.generate(25, (i) => 'm$i');
      final env = PromptBuilder.build(
        l1Persona: '<<MODULE:CHAT>> persona',
        userInput: 'Hi',
        memory: memory,
      );
      final assistantMsgs = env['messages'].where((m) => m['role'] == 'assistant');
      expect(assistantMsgs.length, 20);
    });

    test('size guard ≤64kB', () {
      final env = PromptBuilder.build(
        l1Persona: '<<MODULE:CHAT>> persona',
        userInput: 'Hi',
      );
      expect(utf8.encode(jsonEncode(env)).length <= 64 * 1024, isTrue);
    });

    test('memory window trims to 20 and maintains order', () {
      final mem = List.generate(30, (i) => 'assistant_$i');
      final env = PromptBuilder.build(l1Persona: '<<MODULE:CHAT>>', userInput: 'ping', memory: mem);
      final assistantMsgs = env['messages'].where((m) => m['role']=='assistant').toList();
      expect(assistantMsgs.length, 20);
      expect(assistantMsgs.first['content'], 'assistant_10');
      expect(assistantMsgs.last['content'], 'assistant_29');
    });

    test('envelope byte length ≤ 64 kB', () {
      final huge = 'x' * 17000; // >16 kB per string but <64 kB total after trunc
      final env = PromptBuilder.build(l1Persona: '<<MODULE:CHAT>>', userInput: huge);
      expect(utf8.encode(jsonEncode(env)).length <= 64 * 1024, isTrue);
    });
  });

  group('PromptBuilder goldens', () {
    test('minimal', () {
      final env = PromptBuilder.build(
        l1Persona: '<<MODULE:CHAT>> You are an encouraging **wellness assistant**. Default tone: concise ✨ optimistic.',
        userInput: 'Hi!',
      );
      expect(env, equals(jsonDecode(_injectGlobal(_golden('minimal.json')))));
    });

    test('mode=json', () {
      final env = PromptBuilder.build(
        l1Persona: '<<MODULE:QuickAdd>> Return a single **JSON TaskCreate** with `title` (≤6 words) & `duration` (int, minutes). No commentary.',
        userInput: 'Buy groceries tomorrow at 5',
        requireJson: true,
        l3Ephemeral: SlashRouter.content(SlashCommand.modeJson),
      );
      expect(env, equals(jsonDecode(_injectGlobal(_golden('mode_json.json')))));
    });
  });
}