import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/onboarding/welcome_screen.dart';
import 'package:kira_flutter_client/shared/providers/settings_provider.dart';
import 'package:kira_flutter_client/shared/services/notification_agent.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

void main() {
  testWidgets('welcome screen shows gradient and text', (tester) async {
    // Create a settings provider with firstRunComplete = false
    final settingsProvider = SettingsProvider();
    
    await tester.pumpWidget(
      NotificationAgent(
        child: ChangeNotifierProvider.value(
          value: settingsProvider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const WelcomeScreen(),
          ),
        ),
      ),
    );

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Check that "Welcome" text is displayed
    expect(find.text('Welcome'), findsOneWidget);

    // Check that a Container with LinearGradient decoration exists
    final containerFinder = find.byType(Container);
    expect(containerFinder, findsWidgets);

    // Find the container with the gradient decoration
    final containerWidget = tester.widget<Container>(
      containerFinder.first,
    );
    
    expect(containerWidget.decoration, isA<BoxDecoration>());
    final decoration = containerWidget.decoration as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
    
    final gradient = decoration.gradient as LinearGradient;
    expect(gradient, equals(skyDawnGradient));
  });
}