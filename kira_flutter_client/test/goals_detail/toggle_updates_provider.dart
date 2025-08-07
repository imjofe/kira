import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/goals/goal_detail_screen.dart';
import 'package:kira_flutter_client/models/goal_model.dart';
import 'package:kira_flutter_client/models/goal_detail.dart';
import 'package:kira_flutter_client/models/requirement_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'toggle_updates_provider.mocks.dart';

@GenerateMocks([GoalsProvider])
void main() {
  testWidgets('tapping checkbox calls toggleRequirement', (tester) async {
    const goal = GoalModel(
      id: 1,
      title: 'Test Goal',
      subtitle: 'Test goal subtitle',
      targetTime: TimeOfDay(hour: 1, minute: 0),
    );

    const requirements = [
      RequirementModel(
        id: 101,
        description: 'Test requirement',
        completed: false,
      ),
    ];

    const goalDetail = GoalDetail(goal: goal, reqs: requirements);

    final mockProvider = MockGoalsProvider();
    when(mockProvider.watchGoal(1)).thenReturn(const AsyncValue.data(goalDetail));
    when(mockProvider.toggleRequirement(any, any)).thenAnswer((_) async {});

    await tester.pumpWidget(
      ChangeNotifierProvider<GoalsProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GoalDetailScreen(goalId: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the checkbox and tap it
    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget);
    
    await tester.tap(checkbox);
    await tester.pump();

    // Verify that toggleRequirement was called with the correct parameters
    verify(mockProvider.toggleRequirement(101, true)).called(1);
  });

  testWidgets('tapping checked checkbox calls toggleRequirement with false', (tester) async {
    const goal = GoalModel(
      id: 1,
      title: 'Test Goal',
      subtitle: 'Test goal subtitle',
      targetTime: TimeOfDay(hour: 1, minute: 0),
    );

    const requirements = [
      RequirementModel(
        id: 102,
        description: 'Test requirement',
        completed: true, // Start as completed
      ),
    ];

    const goalDetail = GoalDetail(goal: goal, reqs: requirements);

    final mockProvider = MockGoalsProvider();
    when(mockProvider.watchGoal(1)).thenReturn(const AsyncValue.data(goalDetail));
    when(mockProvider.toggleRequirement(any, any)).thenAnswer((_) async {});

    await tester.pumpWidget(
      ChangeNotifierProvider<GoalsProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GoalDetailScreen(goalId: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the checkbox and tap it
    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget);
    
    await tester.tap(checkbox);
    await tester.pump();

    // Verify that toggleRequirement was called with false (unchecking)
    verify(mockProvider.toggleRequirement(102, false)).called(1);
  });
}