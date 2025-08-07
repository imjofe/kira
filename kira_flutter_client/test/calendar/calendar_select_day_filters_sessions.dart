import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/calendar/calendar_screen.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/models/session_model.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

void main() {
  testWidgets('selecting day filters sessions correctly', (tester) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    
    // Create mock sessions only for tomorrow
    final tomorrowSessions = [
      SessionModel(
        id: 999,
        title: 'Tomorrow Task',
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11, 0),
        status: SessionStatus.pending,
      ),
    ];

    final scheduleProvider = ScheduleProvider(gemma: LlamaBridge(testMode: true));
    scheduleProvider.initWithSeedSessions(tomorrowSessions);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: scheduleProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially, today is selected and should show no sessions
    expect(find.text('Nothing scheduled'), findsOneWidget);

    // Find and tap the second day pill (tomorrow)
    final dayContainers = find.byWidgetPredicate(
      (widget) => widget is GestureDetector &&
          widget.child is Container &&
          ((widget.child as Container).width == 56 ||
              (widget.child as Container).constraints?.maxWidth == 56),
    );

    expect(dayContainers, findsWidgets);
    
    // Tap the second day (tomorrow)
    await tester.tap(dayContainers.at(1));
    await tester.pumpAndSettle();

    // Now should show one session tile
    expect(find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_SessionTile'), findsOneWidget);
    expect(find.text('Tomorrow Task'), findsOneWidget);
    expect(find.text('Nothing scheduled'), findsNothing);
  });
}