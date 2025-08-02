import 'package:flutter/material.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider({DateTime? seed}) : _selected = seed ?? DateTime.now();
  DateTime _selected;
  DateTime get selected => _selected;

  void select(DateTime day) {
    _selected = day;
    notifyListeners();
  }
}
