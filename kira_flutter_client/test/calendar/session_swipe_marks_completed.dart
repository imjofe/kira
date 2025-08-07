import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/calendar/calendar_screen.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/models/session_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart'; // For AsyncValue
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'session_swipe_marks_completed.mocks.dart';

@GenerateMocks([ScheduleProvider])
void main() {
  testWidgets('swiping session right calls completeSession', (tester) async {
    final mockProvider = MockScheduleProvider();
    
    final testSession = SessionModel(
      id: 123,
      title: 'Test Session',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      status: SessionStatus.pending,
    );

    // Mock the watchSessionsForDate to return our test session
    when(mockProvider.watchSessionsForDate(any))
        .thenReturn(AsyncValue.data([testSession]));
    
    // Mock the completeSession method
    when(mockProvider.completeSession(any)).thenAnswer((_) async {});

    await tester.pumpWidget(
      ChangeNotifierProvider<ScheduleProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the session is displayed
    expect(find.text('Test Session'), findsOneWidget);
    expect(find.byType(Dismissible), findsOneWidget);

    // Swipe the session to the right
    await tester.drag(find.byType(Dismissible), const Offset(500, 0));
    await tester.pumpAndSettle();

    // Verify that completeSession was called with the correct session ID
    verify(mockProvider.completeSession(123)).called(1);
  });
}