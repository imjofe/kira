import 'package:flutter/material.dart';

class NotificationAgent extends InheritedWidget {
  const NotificationAgent({
    super.key,
    required super.child,
  });

  /// Localized welcome subtitle text
  String get welcomeSubtitle => 
      'Get ready to organize your life with AI-powered assistance';

  static NotificationAgent of(BuildContext context) {
    final NotificationAgent? result = 
        context.dependOnInheritedWidgetOfExactType<NotificationAgent>();
    assert(result != null, 'No NotificationAgent found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(NotificationAgent oldWidget) => false;
}