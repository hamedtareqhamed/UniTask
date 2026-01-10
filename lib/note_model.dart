class Note {
  String id;
  String title;
  String content;
  DateTime date;
  String? courseId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.courseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'courseId': courseId,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      courseId: map['courseId'],
    );
  }
}
