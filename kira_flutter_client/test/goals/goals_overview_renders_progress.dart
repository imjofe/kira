import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/goals/goals_overview_screen.dart';
import 'package:kira_flutter_client/models/goal_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'goals_overview_renders_progress.mocks.dart';

@GenerateMocks([GoalsProvider])
void main() {
  testWidgets('goals overview renders progress and goal cards', (tester) async {
    // Create mock provider with seeded goals
    final mockProvider = MockGoalsProvider();
    
    final goals = [
      const GoalModel(
        id: 1,
        title: 'Goal 1',
        subtitle: 'First goal',
        targetTime: TimeOfDay(hour: 1, minute: 0),
      ),
      const GoalModel(
        id: 2,
        title: 'Goal 2',
        subtitle: 'Second goal',
        targetTime: TimeOfDay(hour: 0, minute: 30),
      ),
    ];

    // Mock the watchAllGoals to return data
    when(mockProvider.watchAllGoals()).thenReturn(const AsyncValue.data([]));
    
    // Mock progressFor to return specific values
    when(mockProvider.progressFor(goals[0])).thenReturn(0.8);
    when(mockProvider.progressFor(goals[1])).thenReturn(0.6);

    // Create a real provider and initialize it with our test data
    final realProvider = GoalsProvider();
    realProvider.initWithSeed(goals);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: realProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Container(
            decoration: const BoxDecoration(gradient: skyDawnGradient),
            child: const GoalsOverviewScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that CircularPercentIndicator is present
    expect(find.byType(CircularPercentIndicator), findsWidgets);
    
    // Verify that we have goal cards
    expect(find.text('Goal 1'), findsOneWidget);
    expect(find.text('Goal 2'), findsOneWidget);
    expect(find.text('First goal'), findsOneWidget);
    expect(find.text('Second goal'), findsOneWidget);

    // Verify that the main content is shown
    expect(find.text('Your goals'), findsOneWidget);
  });
}