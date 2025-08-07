import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/ui/goals/goal_card.dart';
import 'package:kira_flutter_client/ui/goals/goals_page.dart';
import 'package:kira_flutter_client/ui/goals/goals_provider.dart';
import 'package:provider/provider.dart';

GoalDto _mock() => GoalDto(
      id: 1,
      title: 'Drag me',
      description: 'demo',
      column: 'Backlog',
    );

void main() {
  // Group for pure business logic tests
  group('GoalsProvider Unit Tests', () {
    // Mock the platform channel for all tests in this group
    setUpAll(() {
      const MethodChannel('kira/node')
          .setMockMethodCallHandler((MethodCall methodCall) async => null);
    });

    test('move() changes column correctly', () async {
      final p = GoalsProvider(seed: [_mock()], gemma: LlamaBridge(testMode: true));
      await p.fetch(); // fetch uses the seed
      expect(p.backlog, isNotEmpty);
      await p.move(1, 'Done');
      expect(p.done.single.id, 1);
      expect(p.backlog, isEmpty);
    });
  });

  // Group for widget interaction tests
  group('GoalsPage Widget Tests', () {
    testWidgets('tap ➡ moves goal to next column', (tester) async {
      // 1. Create provider with seed and fetch data
      final provider = GoalsProvider(seed: [_mock()], gemma: LlamaBridge(testMode: true));
      await provider.fetch();

      // 2. Pump the widget tree with the provider
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: GoalsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Verify initial state
      expect(find.byKey(const ValueKey('title_1')), findsOneWidget);
      expect(provider.active, isEmpty);

      // 4. Tap the move button
      await tester.tap(find.byKey(const ValueKey('move_1')));
      await tester.pumpAndSettle();

      // 5. Verify the new state
      expect(provider.active.single.id, 1);
      expect(provider.backlog, isEmpty);
    });
  });
}
