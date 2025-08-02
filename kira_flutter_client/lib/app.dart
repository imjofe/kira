import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kira_flutter_client/bootstrap/kira_scaffold.dart';
import 'package:kira_flutter_client/ui/calendar/calendar_provider.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:provider/provider.dart';

final _router = GoRouter(
  initialLocation: '/schedule',
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/schedule'),
    GoRoute(
      path: '/:tab(schedule|goals|calendar|chat|settings)',
      builder: (ctx, state) => KiraScaffold(tab: state.pathParameters['tab']!),
    ),
  ],
);

class KiraApp extends StatelessWidget {
  const KiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()..fetchToday()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: MaterialApp.router(
        title: 'Kira MVP',
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

const _primaryBlue = Color(0xFF5E8BFF);

final _lightTheme = ThemeData(
  colorSchemeSeed: _primaryBlue,
  useMaterial3: true,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: _primaryBlue,
    unselectedItemColor: Colors.grey,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    selectedIconTheme: IconThemeData(color: _primaryBlue),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
    selectedLabelTextStyle: TextStyle(color: _primaryBlue),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey),
  ),
);

final _darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorSchemeSeed: _primaryBlue,
  useMaterial3: true,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: _primaryBlue,
    unselectedItemColor: Colors.grey,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    selectedIconTheme: IconThemeData(color: _primaryBlue),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
    selectedLabelTextStyle: TextStyle(color: _primaryBlue),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey),
  ),
);
