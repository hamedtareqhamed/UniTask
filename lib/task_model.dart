class Task {
  String name;
  bool isCompleted;
  DateTime? deadline;

  Task({required this.name, this.isCompleted = false, this.deadline});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      name: map['name'],
      isCompleted: map['isCompleted'] ?? false,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : null,
    );
  }
}
