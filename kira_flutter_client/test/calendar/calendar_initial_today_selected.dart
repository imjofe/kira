import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/calendar/calendar_screen.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

void main() {
  testWidgets('calendar screen shows today selected initially', (tester) async {
    final scheduleProvider = ScheduleProvider(gemma: LlamaBridge(testMode: true));

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

    // Find all the day strip containers
    final dayContainers = find.byWidgetPredicate(
      (widget) => widget is Container && (widget.constraints?.maxWidth == 56 || widget.width == 56),
    );

    // Verify that day containers exist
    expect(dayContainers, findsWidgets);

    // Get the first container (today) and verify it's selected (white background)
    final firstContainer = tester.widget<Container>(dayContainers.first);
    final decoration = firstContainer.decoration as BoxDecoration;
    
    // Today should be selected with white background (isSel = true)
    expect(decoration.color, Colors.white);

    // Verify that Calendar title is shown
    expect(find.text('Calendar'), findsOneWidget);
  });
}