import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/goals/goal_detail_screen.dart';
import 'package:kira_flutter_client/models/goal_model.dart';
import 'package:kira_flutter_client/models/goal_detail.dart';
import 'package:kira_flutter_client/models/requirement_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

void main() {
  testWidgets('goal detail renders requirements with correct states', (tester) async {
    // Create test data
    const goal = GoalModel(
      id: 1,
      title: 'Test Goal',
      subtitle: 'Test goal subtitle',
      targetTime: TimeOfDay(hour: 1, minute: 0),
    );

    const requirements = [
      RequirementModel(
        id: 1,
        description: 'First requirement',
        completed: true, // This one is completed
      ),
      RequirementModel(
        id: 2,
        description: 'Second requirement',
        completed: false, // This one is not completed
      ),
    ];

    const goalDetail = GoalDetail(goal: goal, reqs: requirements);

    // Create provider and seed it with test data
    final provider = TestGoalsProvider(goalDetail);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GoalDetailScreen(goalId: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify goal title and subtitle
    expect(find.text('Test Goal'), findsOneWidget);
    expect(find.text('Test goal subtitle'), findsOneWidget);

    // Verify that two CheckboxListTile widgets are rendered
    expect(find.byType(CheckboxListTile), findsNWidgets(2));

    // Verify requirement descriptions
    expect(find.text('First requirement'), findsOneWidget);
    expect(find.text('Second requirement'), findsOneWidget);

    // Find the checkboxes and verify their states
    final checkboxes = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(checkboxes.length, 2);
    
    // First checkbox should be checked (completed: true)
    final firstCheckbox = checkboxes.first;
    expect(firstCheckbox.value, isTrue);
    
    // Second checkbox should be unchecked (completed: false)  
    final secondCheckbox = checkboxes.last;
    expect(secondCheckbox.value, isFalse);

    // Verify recommendations section
    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('Stay consistent! Small steps compound over time.'), findsOneWidget);
  });
}

// Test-specific provider that returns predetermined goal detail
class TestGoalsProvider extends GoalsProvider {
  final GoalDetail _goalDetail;

  TestGoalsProvider(this._goalDetail);

  @override
  AsyncValue<GoalDetail> watchGoal(int goalId) {
    return AsyncValue.data(_goalDetail);
  }
}