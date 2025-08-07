import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:kira_flutter_client/core/prompts/global_prompt.dart';

void main() {
  test('kGlobalSystemPrompt checksum & size constraints', () {
    final checksum = sha256.convert(utf8.encode(kGlobalSystemPrompt)).toString();
    expect(checksum, '193e5d3c75b8909c6c20914fb79467d0d5b00be5c80b5dc1c7c82adbaf387b57');
    expect(kGlobalSystemPrompt.length <= 16 * 1024, isTrue);
  });
}
