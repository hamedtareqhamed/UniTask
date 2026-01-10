class Task {
  String name;
  double score; // Assuming score is out of 100 for example, or simply a grade
  bool isCompleted;

  Task({required this.name, required this.score, this.isCompleted = false});
}
