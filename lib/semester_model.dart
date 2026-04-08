class Semester {
  String id;
  String name;
  DateTime startDate;
  DateTime endDate;

  Semester({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }
}
