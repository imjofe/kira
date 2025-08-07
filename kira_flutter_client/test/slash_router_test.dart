import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/utils/slash_router.dart';

void main() {
  group('SlashRouter', () {
    test('parses whitelisted commands', () {
      expect(SlashRouter.parse('/mode=json'), SlashCommand.modeJson);
      expect(SlashRouter.parse('/debug'), SlashCommand.debug);
    });

    test('rejects unknown commands', () {
      expect(SlashRouter.parse('/hax'), isNull);
      expect(SlashRouter.parse('/sql_drop'), isNull);
    });

    test('content helper round-trip', () {
      final cmd = SlashCommand.summarize;
      final content = SlashRouter.content(cmd);
      expect(SlashRouter.parse(content), cmd);
    });
  });
}
