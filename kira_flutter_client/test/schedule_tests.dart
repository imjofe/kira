import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/ui/schedule/task_card.dart';
import 'package:flutter/material.dart';
import 'package:kira_flutter_client/models/task_dto.dart';
import 'package:flutter/services.dart';

TaskDto _mock() => TaskDto(
      id: 1,
      title: 'Mock task',
      start: DateTime.now(),
      duration: 15,
      status: 'pending',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScheduleProvider', () {
    test('updateStatus mutates list', () async {
      const MethodChannel('kira/node')
          .setMockMethodCallHandler((MethodCall methodCall) async => null);

      final p = ScheduleProvider(testSeed: [_mock()], gemma: LlamaBridge(testMode: true));
      await p.fetchToday();
      expect(p.tasks.first.status, 'pending');
      await p.updateStatus(1, 'done');
      expect(p.tasks.first.status, 'done');
    });
  });

  testWidgets('TaskCard Done button toggles status', (tester) async {
    const MethodChannel('kira/node')
        .setMockMethodCallHandler((MethodCall methodCall) async => null);

    final provider = ScheduleProvider(testSeed: [_mock()], gemma: LlamaBridge(testMode: true))..fetchToday();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: provider.tasks.map((task) => TaskCard(task: task)).toList(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // tap the done icon
    await tester.tap(find.byKey(const ValueKey('done_1')));
    await tester.pump(); // allow notifyListeners

    expect(provider.tasks.first.status, 'done');
  });
}