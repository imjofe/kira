import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/shared/providers/settings_provider.dart';
import 'package:kira_flutter_client/shared/services/notification_agent.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // If first run is already complete, redirect to chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      if (settings.firstRunComplete) {
        if (context.mounted) {
          context.go('/chat');
        }
      }
    });
  }

  Future<void> _completeFirstRun() async {
    final settings = context.read<SettingsProvider>();
    await settings.setFirstRunComplete(true);
    if (mounted) {
      context.go('/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: skyDawnGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  NotificationAgent.of(context).welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _completeFirstRun,
                child: const Text('Ready to start?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}