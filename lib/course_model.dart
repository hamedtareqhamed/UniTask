import 'package:flutter/material.dart';
import 'dart:ui';

/// Enum representing the type of assessment.
enum AssessmentType { quiz, assignment, midterm, finalExam, project, other }

/// Enum representing the grading category.
enum AssessmentCategory { coursework, finalProject }

/// Represents a single assessment (e.g., Quiz, Exam) within a course.
/// Represents a single assessment (e.g., Quiz, Exam) within a course.
class Assessment {
  String id;
  String title;
  AssessmentType type;
  AssessmentCategory category;
  double? score; // Changed to nullable
  double maxScore;
  double weight; // Represents Absolute Points
  DateTime? deadline;
  bool isCompleted;

  Assessment({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    this.score, // Optional
    required this.maxScore,
    required this.weight,
    this.deadline,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.index,
      'category': category.index,
      'score': score, // Can be null
      'maxScore': maxScore,
      'weight': weight,
      'deadline': deadline?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Assessment.fromMap(Map<String, dynamic> map) {
    return Assessment(
      id: map['id'],
      title: map['title'],
      type: AssessmentType.values[map['type']],
      category: AssessmentCategory.values[map['category']],
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
      maxScore: (map['maxScore'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : null,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

/// Represents a Course within the application.
class Course {
  String id;
  String name;
  String professor;
  int credits;
  int colorValue;
  double courseworkWeight;
  double finalWeight;
  List<Assessment> assessments;
  String? semesterId; // Link to semester

  // Weekly Schedule Fields
  String? lectureTime; // Format: "Day HH:mm" e.g., "1 10:00" (1 for Monday)
  String? lectureRoom;
  bool hasTutorial;
  String? tutorialTime;
  String? tutorialRoom;
  bool hasLab;
  String? labTime;
  String? labRoom;

  // Duration fields (in minutes)
  int lectureDuration;
  int tutorialDuration;
  int labDuration;

  bool isPassFail; // PS mode (Success if >= 50, no GPA impact)

  Course({
    required this.id,
    required this.name,
    required this.professor,
    required this.credits,
    required this.colorValue,
    this.courseworkWeight = 60.0,
    this.finalWeight = 40.0,
    List<Assessment>? assessments,
    this.semesterId,
    this.lectureTime,
    this.lectureRoom,
    this.hasTutorial = false,
    this.tutorialTime,
    this.tutorialRoom,
    this.hasLab = false,
    this.labTime,
    this.labRoom,
    this.lectureDuration = 120,
    this.tutorialDuration = 120,
    this.labDuration = 120,
    this.isPassFail = false,
  }) : assessments = assessments ?? [];

  Color get color => Color(colorValue);

  /// Calculates the total grade based on absolute points earned.
  double get totalGrade {
    double totalPoints = 0.0;
    for (var a in assessments) {
      if (a.score != null && a.maxScore > 0) {
        totalPoints += (a.score! / a.maxScore) * a.weight;
      }
    }
    return totalPoints;
  }

  double get courseworkPercentage {
    double points = 0.0;
    for (var a in assessments) {
      if (a.category == AssessmentCategory.coursework &&
          a.score != null &&
          a.maxScore > 0) {
        points += (a.score! / a.maxScore) * a.weight;
      }
    }
    return points;
  }

  double get finalPercentage {
    double points = 0.0;
    for (var a in assessments) {
      if (a.category == AssessmentCategory.finalProject &&
          a.score != null &&
          a.maxScore > 0) {
        points += (a.score! / a.maxScore) * a.weight;
      }
    }
    return points;
  }

  /// The percentage based ONLY on completed/scored assessments.
  /// (e.g. if you got 10/10 so far, this is 100%, even if total weighted is 10%).
  double get gradedPercentage {
    double acquiredTotal = 0.0;
    double weightedTotal = 0.0;
    for (var a in assessments) {
      if (a.score != null && a.maxScore > 0) {
        acquiredTotal += (a.score! / a.maxScore) * a.weight;
        weightedTotal += a.weight;
      }
    }
    if (weightedTotal == 0) return totalGrade;
    return (acquiredTotal / weightedTotal) * 100;
  }

  bool get isPassed {
    if (isPassFail) {
      return totalGrade >= 50.0;
    }
    // Standard Academic Rules
    return courseworkPercentage >= (courseworkWeight * 0.4) &&
        finalPercentage >= (finalWeight * 0.4);
  }

  double get totalPotential {
    final cw = getBreakdown(AssessmentCategory.coursework);
    final fp = getBreakdown(AssessmentCategory.finalProject);
    return (cw['acquired']! + cw['pending']!) +
        (fp['acquired']! + fp['pending']!);
  }

  bool get isImpossibleToPass {
    if (isPassFail) {
      return totalPotential < 50.0;
    }
    final cw = getBreakdown(AssessmentCategory.coursework);
    final fp = getBreakdown(AssessmentCategory.finalProject);
    final cwLost = cw['lost']!;
    final fpLost = fp['lost']!;
    return cwLost > (courseworkWeight * 0.6) || fpLost > (finalWeight * 0.6);
  }

  bool get isCourseworkSecured {
    final cw = getBreakdown(AssessmentCategory.coursework);
    return cw['acquired']! >= (courseworkWeight * 0.4);
  }

  bool get isFinalSecured {
    final fp = getBreakdown(AssessmentCategory.finalProject);
    return fp['acquired']! >= (finalWeight * 0.4);
  }

  Map<String, double> getBreakdown(AssessmentCategory category) {
    double acquired = 0.0;
    double lost = 0.0;
    double totalCategoryPoints = category == AssessmentCategory.coursework
        ? courseworkWeight
        : finalWeight;
    for (var a in assessments) {
      if (a.category == category) {
        double pointsPotential = a.weight;
        if (a.score != null && a.maxScore > 0) {
          double pointsEarned = (a.score! / a.maxScore) * a.weight;
          double pointsMissed = pointsPotential - pointsEarned;
          acquired += pointsEarned;
          lost += pointsMissed;
        }
      }
    }
    double pending = totalCategoryPoints - (acquired + lost);
    if (pending < 0) pending = 0;
    return {'acquired': acquired, 'lost': lost, 'pending': pending};
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'professor': professor,
      'credits': credits,
      'colorValue': colorValue,
      'courseworkWeight': courseworkWeight,
      'finalWeight': finalWeight,
      'assessments': assessments.map((x) => x.toMap()).toList(),
      'semesterId': semesterId,
      'lectureTime': lectureTime,
      'lectureRoom': lectureRoom,
      'hasTutorial': hasTutorial,
      'tutorialTime': tutorialTime,
      'tutorialRoom': tutorialRoom,
      'hasLab': hasLab,
      'labTime': labTime,
      'labRoom': labRoom,
      'lectureDuration': lectureDuration,
      'tutorialDuration': tutorialDuration,
      'labDuration': labDuration,
      'isPassFail': isPassFail,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      name: map['name'],
      professor: map['professor'],
      credits: map['credits'],
      colorValue: map['colorValue'],
      courseworkWeight: (map['courseworkWeight'] ?? 60.0).toDouble(),
      finalWeight: (map['finalWeight'] ?? 40.0).toDouble(),
      assessments: List<Assessment>.from(
        (map['assessments'] as List<dynamic>? ?? []).map<Assessment>(
          (x) => Assessment.fromMap(x),
        ),
      ),
      semesterId: map['semesterId'],
      lectureTime: map['lectureTime'],
      lectureRoom: map['lectureRoom'],
      hasTutorial: map['hasTutorial'] ?? false,
      tutorialTime: map['tutorialTime'],
      tutorialRoom: map['tutorialRoom'],
      hasLab: map['hasLab'] ?? false,
      labTime: map['labTime'],
      labRoom: map['labRoom'],
      lectureDuration: map['lectureDuration'] ?? 120,
      tutorialDuration: map['tutorialDuration'] ?? 120,
      labDuration: map['labDuration'] ?? 120,
      isPassFail: map['isPassFail'] ?? false,
    );
  }
}

