/// SlashRouter — parses *whitelisted* L3 slash-commands.
///
/// Spec ref: system_prompt_architecture.md §7 (Ephemeral Instructions)
/// Allowed examples (§7, §12): /mode=json, /debug, /summarize, /sql, /rephrase
/// Unknown commands → ignored (fail-closed).

enum SlashCommand { modeJson, debug, summarize, sql, rephrase }

class SlashRouter {
  static const Map<String, SlashCommand> _allowed = {
    '/mode=json': SlashCommand.modeJson,
    '/debug': SlashCommand.debug,
    '/summarize': SlashCommand.summarize,
    '/sql': SlashCommand.sql,
    '/rephrase': SlashCommand.rephrase,
  };

  /// Returns the [SlashCommand] if `text` **exactly** matches a whitelisted
  /// command (case-sensitive). Otherwise returns `null`.
  static SlashCommand? parse(String text) => _allowed[text];

  /// Helper → returns the correct *content* string for the given command.
  /// Usage: PromptBuilder.build(l3Ephemeral: SlashRouter.content(SlashCommand.modeJson))
  static String content(SlashCommand cmd) => _allowed.entries
      .firstWhere((e) => e.value == cmd)
      .key;
}
