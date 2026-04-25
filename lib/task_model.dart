class Task {
  String name;
  bool isCompleted;
  DateTime? deadline;
  String? semesterId;

  Task({
    required this.name,
    this.isCompleted = false,
    this.deadline,
    this.semesterId,
    this.reminderMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),
      'semesterId': semesterId,
      'reminderMinutes': reminderMinutes,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      name: map['name'],
      isCompleted: map['isCompleted'] ?? false,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      semesterId: map['semesterId'],
      reminderMinutes: map['reminderMinutes'],
    );
  }
  int? reminderMinutes;
}

