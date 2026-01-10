class Task {
  String name;
  double score; // Assuming score is out of 100 for example, or simply a grade
  bool isCompleted;
  String? courseId;

  Task({
    required this.name,
    required this.score,
    this.isCompleted = false,
    this.courseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'score': score,
      'isCompleted': isCompleted,
      'courseId': courseId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      name: map['name'],
      score: map['score'],
      isCompleted: map['isCompleted'] ?? false,
      courseId: map['courseId'],
    );
  }
}
