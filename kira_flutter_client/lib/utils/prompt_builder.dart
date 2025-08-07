import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kira_flutter_client/core/prompts/global_prompt.dart';

/// Builds the canonical prompt envelope for Gemma.
///
/// Spec ref: system_prompt_architecture.d §3 (v1.1)
class PromptBuilder {
  static const _memoryLimit = 20;            // L2 sliding-window cap
  static const _maxEnvelopeBytes = 64 * 1024; // ≤64 kB overall
  static const _maxStringBytes = 16 * 1024;   // ≤16 kB per string

  /// Assemble a prompt envelope.
  ///
  /// * [l1Persona] – MUST include identity tag, e.g. `<<MODULE:CHAT>> ...`.
  /// * [userInput] – Latest user text (L0 size rules enforced).
  /// * [memory] – Last N assistant messages (L2). Oldest trimmed first.
  /// * [l3Ephemeral] – One-shot / slash-command (L3). Optional.
  /// * [requireJson] – When true, sets metadata.require_json, triggering L0 rule 5.
  static Map<String, dynamic> build({
    required String l1Persona,
    required String userInput,
    List<String> memory = const [],
    String? l3Ephemeral,
    bool requireJson = false,
  }) {
    // 1. Trim memory window.
    final trimmedMemory = memory.length <= _memoryLimit
        ? memory
        : memory.sublist(memory.length - _memoryLimit);

    // 2. Assemble message list.
    final List<Map<String, String>> messages = [
      {"role": "system", "content": kGlobalSystemPrompt},
      {"role": "system", "content": l1Persona},
      ...trimmedMemory.map((m) => {"role": "assistant", "content": _truncate(m)}),
      {"role": "user", "content": _truncate(userInput)},
    ];

    if (l3Ephemeral != null && l3Ephemeral.isNotEmpty) {
      messages.add({"role": "system", "content": l3Ephemeral, "name": "ephemeral"});
    }

    // 3. Build envelope.
    final envelope = {
      "messages": messages,
      "metadata": {"prompt_version": "1.1", "require_json": requireJson}
    };

    // 4. Size guard (debug-only in release).
    assert(_byteLength(jsonEncode(envelope)) <= _maxEnvelopeBytes,
        "Prompt envelope exceeds ${_maxEnvelopeBytes / 1024} kB Gemma limit");

    // 5. Optional debug print.
    if (!kReleaseMode) {
      debugPrint("[PromptBuilder] Envelope → ${jsonEncode(envelope)}");
    }

    return envelope;
  }

  /// Truncate overly long strings to spec-compliant byte length.
  static String _truncate(String input) {
    final bytes = utf8.encode(input);
    if (bytes.length <= _maxStringBytes) return input;
    return utf8.decode(bytes.sublist(0, _maxStringBytes));
  }

  static int _byteLength(String s) => utf8.encode(s).length;
}