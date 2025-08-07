import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/goals/goal_detail_screen.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'goal_detail_loading.mocks.dart';

@GenerateMocks([GoalsProvider])
void main() {
  testWidgets('goal detail shows loading indicator', (tester) async {
    final mockProvider = MockGoalsProvider();
    when(mockProvider.watchGoal(1)).thenReturn(const AsyncValue.loading());

    await tester.pumpWidget(
      ChangeNotifierProvider<GoalsProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GoalDetailScreen(goalId: 1),
        ),
      ),
    );

    await tester.pump();

    // Verify that CircularProgressIndicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Verify that the content is not shown yet (since we're in loading state)
    expect(find.text('Could not load goal'), findsNothing);
  });
}