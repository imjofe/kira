import 'package:kira_flutter_client/models/goal_model.dart';
import 'package:kira_flutter_client/models/requirement_model.dart';

class GoalDetail {
  final GoalModel goal;
  final List<RequirementModel> reqs;

  const GoalDetail({
    required this.goal,
    required this.reqs,
  });

  GoalDetail copyWith({
    GoalModel? goal,
    List<RequirementModel>? reqs,
  }) {
    return GoalDetail(
      goal: goal ?? this.goal,
      reqs: reqs ?? this.reqs,
    );
  }

  Map<String, dynamic> toJson() => {
    'goal': goal.toJson(),
    'reqs': reqs.map((r) => r.toJson()).toList(),
  };

  factory GoalDetail.fromJson(Map<String, dynamic> json) {
    return GoalDetail(
      goal: GoalModel.fromJson(json['goal'] as Map<String, dynamic>),
      reqs: (json['reqs'] as List<dynamic>)
          .map((r) => RequirementModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalDetail &&
          runtimeType == other.runtimeType &&
          goal == other.goal &&
          _listEquals(reqs, other.reqs);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => goal.hashCode ^ reqs.hashCode;

  @override
  String toString() => 'GoalDetail(goal: $goal, reqs: $reqs)';
}