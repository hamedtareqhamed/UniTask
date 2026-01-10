import 'package:flutter/material.dart';

class Course {
  String id;
  String name;
  String professor;
  int credits;
  int colorValue; // Store color as int for JSON serialization

  List<Assessment> assessments;
  double courseworkWeight;
  double finalWeight;

  Course({
    required this.id,
    required this.name,
    required this.professor,
    required this.credits,
    required this.colorValue,
    this.assessments = const [],
    this.courseworkWeight = 60.0,
    this.finalWeight = 40.0,
  });

  Color get color => Color(colorValue);

  // Logic: 0.0 to 100.0
  double get totalGrade {
    double totalPoints = 0;
    for (var a in assessments) {
      if (a.maxScore > 0) {
        totalPoints += (a.score / a.maxScore) * a.weight;
      }
    }
    return totalPoints;
  }

  double get courseworkPercentage {
    double earned = 0;
    for (var a in assessments.where(
      (a) => a.category == AssessmentCategory.coursework,
    )) {
      if (a.maxScore > 0) {
        earned += (a.score / a.maxScore) * a.weight;
      }
    }
    return courseworkWeight == 0 ? 0 : (earned / courseworkWeight) * 100;
  }

  double get finalPercentage {
    double earned = 0;
    for (var a in assessments.where(
      (a) => a.category == AssessmentCategory.finalProject,
    )) {
      if (a.maxScore > 0) {
        earned += (a.score / a.maxScore) * a.weight;
      }
    }
    return finalWeight == 0 ? 0 : (earned / finalWeight) * 100;
  }

  bool get isPassed {
    return courseworkPercentage >= 40 && finalPercentage >= 40;
  }

  Map<String, double> getBreakdown(AssessmentCategory category) {
    double acquired = 0;
    double lost = 0;
    double totalCategoryWeight = category == AssessmentCategory.coursework
        ? courseworkWeight
        : finalWeight;

    for (var a in assessments) {
      if (a.category == category) {
        double aScore = a.score;
        double aMax = a.maxScore;
        if (aMax > 0) {
          acquired += (aScore / aMax) * a.weight;
          lost += ((aMax - aScore) / aMax) * a.weight;
        }
      }
    }

    double remaining = totalCategoryWeight - (acquired + lost);
    if (remaining < 0) remaining = 0;

    return {'acquired': acquired, 'lost': lost, 'remaining': remaining};
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'professor': professor,
      'credits': credits,
      'colorValue': colorValue,
      'assessments': assessments.map((x) => x.toMap()).toList(),
      'courseworkWeight': courseworkWeight,
      'finalWeight': finalWeight,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      name: map['name'],
      professor: map['professor'],
      credits: map['credits'],
      colorValue: map['colorValue'],
      assessments: List<Assessment>.from(
        (map['assessments'] as List<dynamic>? ?? []).map<Assessment>(
          (x) => Assessment.fromMap(x),
        ),
      ),
      courseworkWeight: map['courseworkWeight'] ?? 60.0,
      finalWeight: map['finalWeight'] ?? 40.0,
    );
  }
}

enum AssessmentType { quiz, assignment, project, exam }

enum AssessmentCategory { coursework, finalProject }

class Assessment {
  String id;
  String title;
  AssessmentType type;
  AssessmentCategory category;
  double score;
  double maxScore;
  double
  weight; // Percentage weight in total grade (optional for now, or derived)
  DateTime? deadline;

  Assessment({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.score,
    required this.maxScore,
    required this.weight,
    this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.index,
      'category': category.index,
      'score': score,
      'maxScore': maxScore,
      'weight': weight,
      'deadline': deadline?.toIso8601String(),
    };
  }

  factory Assessment.fromMap(Map<String, dynamic> map) {
    return Assessment(
      id: map['id'],
      title: map['title'],
      type: AssessmentType.values[map['type']],
      category: AssessmentCategory.values[map['category']],
      score: map['score'],
      maxScore: map['maxScore'],
      weight: map['weight'],
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : null,
    );
  }
}
