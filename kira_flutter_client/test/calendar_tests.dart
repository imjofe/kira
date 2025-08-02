import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/models/task_dto.dart';
import 'package:kira_flutter_client/ui/calendar/calendar_page.dart';
import 'package:kira_flutter_client/ui/calendar/calendar_provider.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:provider/provider.dart';

// Helper to create a mock task for a specific day
TaskDto _mock(DateTime when) => TaskDto(
      id: when.day,
      title: 'Task ${when.day}',
      start: when,
      duration: 30,
      status: 'pending',
    );

void main() {
  testWidgets('tap day shows tasks in a bottom sheet', (tester) async {
    // 1. ARRANGE: Create a predictable date for the test
    final seedDay = DateTime(2025, 1, 1); // A fixed Wednesday

    // 2. ARRANGE: Seed the provider with tasks on that specific day
    final scheduleProvider = ScheduleProvider(testSeed: [
      _mock(seedDay.add(const Duration(hours: 9))),
      _mock(seedDay.add(const Duration(hours: 14))),
    ])..fetchToday();

    // 3. ARRANGE: Pump the widget tree with the seeded providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: scheduleProvider),
          // Ensure the calendar is focused on the same day
          ChangeNotifierProvider(create: (_) => CalendarProvider(seed: seedDay)),
        ],
        child: const MaterialApp(home: CalendarPage(testing: true)), // enable keys
      ),
    );
    await tester.pumpAndSettle();

    // 4. ACT: Tap the day cell in the calendar
    await tester.tap(find.byKey(const Key('day_20250101')));
    await tester.pumpAndSettle(); // Wait for bottom sheet animation

    // 5. ASSERT: Verify that the bottom sheet now shows the two tasks
    expect(find.text('Task 1'), findsNWidgets(2));
  });
}
