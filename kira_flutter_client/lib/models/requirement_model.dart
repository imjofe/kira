class RequirementModel {
  final int id;
  final String description;
  final bool completed;

  const RequirementModel({
    required this.id,
    required this.description,
    required this.completed,
  });

  RequirementModel copyWith({
    int? id,
    String? description,
    bool? completed,
  }) {
    return RequirementModel(
      id: id ?? this.id,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'completed': completed,
  };

  factory RequirementModel.fromJson(Map<String, dynamic> json) {
    return RequirementModel(
      id: json['id'] as int,
      description: json['description'] as String,
      completed: json['completed'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequirementModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          description == other.description &&
          completed == other.completed;

  @override
  int get hashCode => id.hashCode ^ description.hashCode ^ completed.hashCode;

  @override
  String toString() => 'RequirementModel(id: $id, description: $description, completed: $completed)';
}