import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_model.dart';

class ReadyMadeEntry {
  final String courseCode; // e.g., TSE
  final String className; // e.g., DS1D
  final String lecTime;
  final String labTime;
  final String lecRoom;
  final String labRoom;
  final String instructor;
  final int credits;
  final double courseworkWeight;

  ReadyMadeEntry({
    required this.courseCode,
    required this.className,
    required this.lecTime,
    required this.labTime,
    required this.lecRoom,
    required this.labRoom,
    required this.instructor,
    required this.credits,
    required this.courseworkWeight,
  });
}

class ReadyMadeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Map<String, String> fileNameMapping = {
    'TSW': 'SEMANTIC WEB TECHNOLOGY',
    'TML': 'MACHINE LEARNING',
    'TWT': 'WEB TECHNIQUES',
    'TSE': 'SOFTWARE ENGINE',
    'THI': 'HUMAN COMPUTER',
    'TCG': 'COMPUTER GRAPHICS',
  };

  /// Loads sections from Firestore.
  Future<List<ReadyMadeEntry>> loadSections() async {
    try {
      final snapshot = await _firestore.collection('ready_made_sections').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ReadyMadeEntry(
          className: doc.id,
          courseCode: data['courseCode'] ?? '',
          lecTime: data['lecTime'] ?? '',
          labTime: data['labTime'] ?? '',
          lecRoom: data['lecRoom'] ?? '',
          labRoom: data['labRoom'] ?? '',
          instructor: data['instructor'] ?? '',
          credits: (data['credits'] ?? 3).toInt(),
          courseworkWeight: (data['courseworkWeight'] ?? 60.0).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Error loading sections from Firestore: $e');
      return [];
    }
  }

  /// Loads assessments for a specific course code from Firestore.
  Future<List<Assessment>> loadAssessments(String courseCode) async {
    try {
      final snapshot = await _firestore
          .collection('ready_made_courses')
          .doc(courseCode)
          .collection('assessments')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Assessment(
          id: DateTime.now().millisecondsSinceEpoch.toString() + doc.id,
          title: data['title'] ?? 'Assessment',
          type: _parseType(data['type'] ?? 'other'),
          category: _parseCategory(data['category'] ?? 'coursework'),
          maxScore: (data['maxScore'] ?? 10.0).toDouble(),
          weight: (data['weight'] ?? 10.0).toDouble(),
          deadline: _parseDate(data['deadline'] ?? ''),
          isCompleted: data['isCompleted'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Error loading assessments from Firestore for $courseCode: $e');
      return [];
    }
  }

  AssessmentType _parseType(String val) {
    val = val.toLowerCase().trim();
    if (val.contains('quiz')) return AssessmentType.quiz;
    if (val.contains('assignment')) return AssessmentType.assignment;
    if (val.contains('midterm')) return AssessmentType.midterm;
    if (val.contains('final')) return AssessmentType.finalExam;
    if (val.contains('project')) return AssessmentType.project;
    return AssessmentType.other;
  }

  AssessmentCategory _parseCategory(String val) {
    val = val.toLowerCase().trim();
    if (val.contains('final')) return AssessmentCategory.finalProject;
    return AssessmentCategory.coursework;
  }

  DateTime? _parseDate(String val) {
    try {
      return DateTime.parse(val);
    } catch (_) {
      return null;
    }
  }

  /// Converts "Monday 2:00PM" to "1 14:00" mapping (1=Mon)
  String? convertTimeFormat(String raw) {
    if (raw.isEmpty || raw.toLowerCase() == 'none' || raw == 'null') return null;
    
    final days = {
      'monday': '1', 'tuesday': '2', 'wednesday': '3', 
      'thursday': '4', 'friday': '5', 'saturday': '6', 'sunday': '7'
    };

    final parts = raw.split(' ');
    if (parts.length < 2) return null;

    final day = days[parts[0].toLowerCase()];
    if (day == null) return null;

    final timePart = parts[1].toUpperCase();
    final isPM = timePart.contains('PM');
    final timeStr = timePart.replaceAll(RegExp(r'[AP]M'), '');
    final timeParts = timeStr.split(':');
    
    int hour = int.tryParse(timeParts[0]) ?? 0;
    int minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

    if (isPM && hour < 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return '$day ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
