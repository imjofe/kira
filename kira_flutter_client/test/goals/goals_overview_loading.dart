import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/goals/goals_overview_screen.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'goals_overview_loading.mocks.dart';

@GenerateMocks([GoalsProvider])
void main() {
  testWidgets('goals overview shows loading indicator', (tester) async {
    // Create mock provider in loading state
    final mockProvider = MockGoalsProvider();
    when(mockProvider.watchAllGoals()).thenReturn(const AsyncValue.loading());

    await tester.pumpWidget(
      ChangeNotifierProvider<GoalsProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Container(
            decoration: const BoxDecoration(gradient: skyDawnGradient),
            child: const GoalsOverviewScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify that CircularProgressIndicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Verify that the loading text is not shown yet (since we're in loading state)
    expect(find.text('Your goals'), findsNothing);
  });
}