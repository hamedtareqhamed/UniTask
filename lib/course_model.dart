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
      score: map['score'], // Can be null
      maxScore: map['maxScore'],
      weight: map['weight'],
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

  Course({
    required this.id,
    required this.name,
    required this.professor,
    required this.credits,
    required this.colorValue,
    this.courseworkWeight = 60.0,
    this.finalWeight = 40.0,
    List<Assessment>? assessments,
  }) : assessments = assessments ?? [];

  Color get color => Color(colorValue);

  /// Calculates the total grade based on absolute points earned.
  ///
  /// Formula: Sum of ( (score / maxScore) * weight ) for all assessments.
  double get totalGrade {
    double totalPoints = 0.0;
    for (var a in assessments) {
      if (a.score != null && a.maxScore > 0) {
        totalPoints += (a.score! / a.maxScore) * a.weight;
      }
    }
    return totalPoints;
  }

  /// Calculates the points earned for the Coursework category.
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

  /// Calculates the points earned for the Final/Project category.
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

  /// Determines if the course is passed (threshold: 40% in each category).
  ///
  /// This logic might need adjustment based on specific university rules.
  /// Currently checks if >= 40% of the possible points in each category are earned.
  /// Note: This logic assumes 'percentage' getters return Points, so we compare
  /// against 40% of the Category Weight.
  bool get isPassed {
    return courseworkPercentage >= (courseworkWeight * 0.4) &&
        finalPercentage >= (finalWeight * 0.4);
  }

  /// Calculates the total potential score (Acquired + Remaining).
  double get totalPotential {
    final cw = getBreakdown(AssessmentCategory.coursework);
    final fp = getBreakdown(AssessmentCategory.finalProject);
    // Potential = Acquired + Remaining
    return (cw['acquired']! + cw['pending']!) +
        (fp['acquired']! + fp['pending']!);
  }

  /// Determines if it is mathematically impossible to pass.
  /// Returns true if "Lost" points exceed 60% of the weight in ANY category.
  bool get isImpossibleToPass {
    final cw = getBreakdown(AssessmentCategory.coursework);
    final fp = getBreakdown(AssessmentCategory.finalProject);

    final cwLost = cw['lost']!;
    final fpLost = fp['lost']!;

    return cwLost > (courseworkWeight * 0.6) || fpLost > (finalWeight * 0.6);
  }

  /// Checks if the Coursework category is secured (> 40% acquired).
  bool get isCourseworkSecured {
    final cw = getBreakdown(AssessmentCategory.coursework);
    return cw['acquired']! >= (courseworkWeight * 0.4);
  }

  /// Checks if the Final/Project category is secured (> 40% acquired).
  bool get isFinalSecured {
    final fp = getBreakdown(AssessmentCategory.finalProject);
    return fp['acquired']! >= (finalWeight * 0.4);
  }

  /// Calculates the breakdown of points (Acquired, Lost, Pending) for a category.
  Map<String, double> getBreakdown(AssessmentCategory category) {
    double acquired = 0.0;
    double lost = 0.0;
    double totalCategoryPoints = category == AssessmentCategory.coursework
        ? courseworkWeight
        : finalWeight;

    for (var a in assessments) {
      if (a.category == category) {
        double pointsPotential = a.weight;

        // Only count towards acquired/lost if graded (score is not null)
        if (a.score != null && a.maxScore > 0) {
          double pointsEarned = (a.score! / a.maxScore) * a.weight;
          double pointsMissed = pointsPotential - pointsEarned;

          acquired += pointsEarned;
          lost += pointsMissed;
        }
      }
    }

    double pending = totalCategoryPoints - (acquired + lost);
    // Ensure pending doesn't go below zero
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
    );
  }
}
