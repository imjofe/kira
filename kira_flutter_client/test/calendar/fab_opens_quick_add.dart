import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/calendar/calendar_screen.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/ui/schedule/quick_add_sheet.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

void main() {
  testWidgets('FAB opens QuickAdd modal', (tester) async {
    final scheduleProvider = ScheduleProvider(gemma: LlamaBridge(testMode: true));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: scheduleProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify FAB is present
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    expect(find.text('Quick Add'), findsOneWidget);

    // Tap the FAB
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify that QuickAddSheet modal is shown
    expect(find.byType(QuickAddSheet), findsOneWidget);
    
    // Verify modal content (from the existing QuickAddSheet implementation)
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    
    // Verify dropdown with duration options
    expect(find.text('15 min'), findsOneWidget);
  });

  testWidgets('QuickAdd modal can be dismissed', (tester) async {
    final scheduleProvider = ScheduleProvider(gemma: LlamaBridge(testMode: true));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: scheduleProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open the modal
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify modal is open
    expect(find.byType(QuickAddSheet), findsOneWidget);

    // Tap the "Save" button to dismiss the modal
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify modal is dismissed
    expect(find.byType(QuickAddSheet), findsNothing);
  });
}