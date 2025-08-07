import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/router.dart';
import 'package:kira_flutter_client/shared/providers/settings_provider.dart';
import 'package:kira_flutter_client/shared/services/notification_agent.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';
import 'package:kira_flutter_client/ui/calendar/calendar_provider.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/services/node_service.dart';

final _llamaBridge = LlamaBridge();

class KiraApp extends StatefulWidget {
  const KiraApp({super.key});

  @override
  State<KiraApp> createState() {
    print('[KiraApp] createState called');
    return _KiraAppState();
  }
}

class _KiraAppState extends State<KiraApp> {
  late SettingsProvider _settingsProvider;

  @override
  void initState() {
    print('[KiraApp] initState called - ENTRY');
    super.initState();
    print('[KiraApp] Initializing app...');
    _initializeApp();
    _settingsProvider = SettingsProvider();
    _settingsProvider.loadSettings();
    print('[KiraApp] initState completed');
  }

  void _initializeApp() async {
    try {
      print('[KiraApp] Starting NodeService...');
      NodeService.instance.start();
      
      print('[KiraApp] Loading model...');
      await _llamaBridge.load("gemma-wellness-f16.gguf");
      print('[KiraApp] Model loading completed successfully');
    } catch (error) {
      print('[KiraApp] Model loading failed: $error');
      // Continue without model - app should still work
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationAgent(
      child: MultiProvider(
        providers: [
          Provider.value(value: _llamaBridge),
          ChangeNotifierProvider.value(value: _settingsProvider),
          ChangeNotifierProvider(create: (context) => ScheduleProvider(gemma: context.read<LlamaBridge>())..fetchToday()),
          ChangeNotifierProvider(create: (context) => CalendarProvider(gemma: context.read<LlamaBridge>())),
        ],
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return MaterialApp.router(
              title: 'Kira MVP',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              routerConfig: createRouter(settings),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}

