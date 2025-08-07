import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kira_flutter_client/models/goal_model.dart';
import 'package:kira_flutter_client/models/goal_detail.dart';
import 'package:kira_flutter_client/models/requirement_model.dart';

class AsyncValue<T> {
  final T? data;
  final Object? error;
  final bool isLoading;

  const AsyncValue.data(this.data) : error = null, isLoading = false;
  const AsyncValue.error(this.error) : data = null, isLoading = false;
  const AsyncValue.loading() : data = null, error = null, isLoading = true;

  R when<R>({
    required R Function(T data) data,
    required R Function(Object error) error,
    required R Function() loading,
  }) {
    if (isLoading) return loading();
    if (this.error != null) return error(this.error!);
    return data(this.data as T);
  }
}

class GoalsProvider extends ChangeNotifier {
  AsyncValue<List<GoalModel>> _watchAllGoals = const AsyncValue.loading();
  List<GoalModel>? _seedGoals;
  final Map<int, AsyncValue<GoalDetail>> _goalDetails = {};

  AsyncValue<List<GoalModel>> watchAllGoals() => _watchAllGoals;

  // Initialize with seed data for testing
  void initWithSeed(List<GoalModel> goals) {
    _seedGoals = goals;
    _watchAllGoals = AsyncValue.data(goals);
    notifyListeners();
  }

  // Simulate loading goals
  Future<void> loadGoals() async {
    _watchAllGoals = const AsyncValue.loading();
    notifyListeners();

    try {
      // Only add delay if not in test mode
      if (!_isInTestMode()) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // If we have seed data, use it; otherwise use default goals
      final goals = _seedGoals ?? _defaultGoals();
      _watchAllGoals = AsyncValue.data(goals);
    } catch (e) {
      _watchAllGoals = AsyncValue.error(e);
    }
    
    notifyListeners();
  }

  bool _isInTestMode() {
    // Simple check for test environment
    bool inTestMode = false;
    assert(() {
      inTestMode = true;
      return true;
    }());
    return inTestMode;
  }

  List<GoalModel> _defaultGoals() {
    return [
      GoalModel(
        id: 1,
        title: 'Morning Exercise',
        subtitle: 'Stay healthy with daily workouts',
        targetTime: const TimeOfDay(hour: 1, minute: 0),
      ),
      GoalModel(
        id: 2,
        title: 'Read Books',
        subtitle: 'Expand knowledge through reading',
        targetTime: const TimeOfDay(hour: 0, minute: 30),
      ),
      GoalModel(
        id: 3,
        title: 'Learn Programming',
        subtitle: 'Build coding skills',
        targetTime: const TimeOfDay(hour: 2, minute: 0),
      ),
    ];
  }

  // Calculate progress for a specific goal (0.0 to 1.0)
  double progressFor(GoalModel goal) {
    // Simple placeholder implementation - return random progress for demo
    final random = Random(goal.id);
    return random.nextDouble();
  }

  // Watch a specific goal with its requirements
  AsyncValue<GoalDetail> watchGoal(int goalId) {
    // Return cached result if available
    if (_goalDetails.containsKey(goalId)) {
      return _goalDetails[goalId]!;
    }

    // Start loading this goal
    _loadGoalDetail(goalId);
    return const AsyncValue.loading();
  }

  Future<void> _loadGoalDetail(int goalId) async {
    _goalDetails[goalId] = const AsyncValue.loading();
    notifyListeners();

    try {
      // Only add delay if not in test mode
      if (!_isInTestMode()) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Find the goal from our loaded goals
      final goals = _watchAllGoals.data ?? _seedGoals ?? _defaultGoals();
      final goal = goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => throw Exception('Goal not found'),
      );

      // Create mock requirements for this goal
      final requirements = _createMockRequirements(goalId);
      
      final goalDetail = GoalDetail(goal: goal, reqs: requirements);
      _goalDetails[goalId] = AsyncValue.data(goalDetail);
    } catch (e) {
      _goalDetails[goalId] = AsyncValue.error(e);
    }
    
    notifyListeners();
  }

  List<RequirementModel> _createMockRequirements(int goalId) {
    // Create mock requirements based on goal ID for demo purposes
    final baseRequirements = [
      'Complete daily practice session',
      'Track progress in journal',
      'Review weekly goals',
      'Reflect on achievements',
    ];

    return baseRequirements.asMap().entries.map((entry) {
      final index = entry.key;
      final description = entry.value;
      return RequirementModel(
        id: goalId * 100 + index, // Unique ID based on goal and requirement index
        description: description,
        completed: _getRandomCompletion(goalId, index), // Some demo completion state
      );
    }).toList();
  }

  bool _getRandomCompletion(int goalId, int reqIndex) {
    // Deterministic but varied completion states for demo
    final seed = goalId * 7 + reqIndex * 3;
    return (seed % 3) == 0; // About 1/3 completed
  }

  Future<void> toggleRequirement(int requirementId, bool newValue) async {
    // Find which goal detail contains this requirement
    for (final entry in _goalDetails.entries) {
      final goalDetail = entry.value.data;
      if (goalDetail != null) {
        final reqIndex = goalDetail.reqs.indexWhere((r) => r.id == requirementId);
        if (reqIndex != -1) {
          // Update the requirement
          final updatedReqs = List<RequirementModel>.from(goalDetail.reqs);
          updatedReqs[reqIndex] = updatedReqs[reqIndex].copyWith(completed: newValue);
          
          // Update the goal detail
          final updatedDetail = goalDetail.copyWith(reqs: updatedReqs);
          _goalDetails[entry.key] = AsyncValue.data(updatedDetail);
          
          notifyListeners();
          
          // Simulate persistence (would normally call a database)
          if (!_isInTestMode()) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
          break;
        }
      }
    }
  }

  // Simulate error state for testing
  void simulateError() {
    _watchAllGoals = const AsyncValue.error('Failed to load goals');
    notifyListeners();
  }

  void simulateGoalError(int goalId) {
    _goalDetails[goalId] = const AsyncValue.error('Failed to load goal detail');
    notifyListeners();
  }
}
