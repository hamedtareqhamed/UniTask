import 'course_model.dart';

class GPAUtils {
  /// Returns the current time in Malaysia (UTC+8).
  static DateTime getMalaysiaTime() {
    return DateTime.now().toUtc().add(const Duration(hours: 8));
  }

  /// Calculates the points for a given percentage based on the 4.0 scale.
  static double calculatePoints(double mark) {
    if (mark >= 80.0) return 4.00;
    if (mark >= 79.0) return 3.93;
    if (mark >= 78.0) return 3.87;
    if (mark >= 77.0) return 3.80;
    if (mark >= 76.0) return 3.73;
    if (mark >= 75.0) return 3.67;
    if (mark >= 74.0) return 3.60;
    if (mark >= 73.0) return 3.53;
    if (mark >= 72.0) return 3.47;
    if (mark >= 71.0) return 3.40;
    if (mark >= 70.0) return 3.33;
    if (mark >= 69.0) return 3.27;
    if (mark >= 68.0) return 3.20;
    if (mark >= 67.0) return 3.13;
    if (mark >= 66.0) return 3.07;
    if (mark >= 65.0) return 3.00;
    if (mark >= 64.0) return 2.93;
    if (mark >= 63.0) return 2.87;
    if (mark >= 62.0) return 2.80;
    if (mark >= 61.0) return 2.73;
    if (mark >= 60.0) return 2.67;
    if (mark >= 59.0) return 2.59;
    if (mark >= 58.0) return 2.53;
    if (mark >= 57.0) return 2.46;
    if (mark >= 56.0) return 2.40;
    if (mark >= 55.0) return 2.33;
    if (mark >= 54.0) return 2.26;
    if (mark >= 53.0) return 2.20;
    if (mark >= 52.0) return 2.13;
    if (mark >= 51.0) return 2.07;
    if (mark >= 50.0) return 2.00;
    if (mark >= 47.0) return 1.67;
    if (mark >= 44.0) return 1.33;
    if (mark >= 40.0) return 1.00;
    return 0.00;
  }

  /// Returns both Letter Grade and Points for a given absolute mark.
  static Map<String, dynamic> getGradeInfo(double mark) {
    String letter = 'F';
    if (mark >= 90.0) {
      letter = 'A+';
    } else if (mark >= 80.0) {
      letter = 'A';
    } else if (mark >= 75.0) {
      letter = 'A-';
    } else if (mark >= 70.0) {
      letter = 'B+';
    } else if (mark >= 65.0) {
      letter = 'B';
    } else if (mark >= 60.0) {
      letter = 'B-';
    } else if (mark >= 55.0) {
      letter = 'C+';
    } else if (mark >= 50.0) {
      letter = 'C';
    } else if (mark >= 47.0) {
      letter = 'C-';
    } else if (mark >= 44.0) {
      letter = 'D+';
    } else if (mark >= 40.0) {
      letter = 'D';
    }
    
    if (mark >= 75.0 && mark < 80.0) {
      letter = 'A-';
    }
    if (mark >= 70.0 && mark < 75.0) {
      letter = 'B+';
    }
    if (mark >= 65.0 && mark < 70.0) {
      letter = 'B';
    }
    if (mark >= 60.0 && mark < 65.0) {
      letter = 'B-';
    }

    return {
      'letter': letter,
      'points': calculatePoints(mark),
    };
  }

  /// Calculates the current GPA based on graded work (trajectory).
  static double calculateCurrentGPA(List<Course> courses) {
    double totalWeightedPoints = 0.0;
    int totalCredits = 0;

    for (var course in courses) {
      if (course.isPassFail) continue; 
      
      // We use gradedPercentage here to show the trajectory (current standing)
      double points = calculatePoints(course.gradedPercentage);
      totalWeightedPoints += points * course.credits;
      totalCredits += course.credits;
    }

    if (totalCredits == 0) return 0.0;
    return totalWeightedPoints / totalCredits;
  }

  /// Calculates the minimum possible GPA (assuming all pending work fails).
  static double calculateMinGPA(List<Course> courses) {
    double totalWeightedPoints = 0.0;
    int totalCredits = 0;

    for (var course in courses) {
      if (course.isPassFail) continue;
      
      // For min GPA, we only consider current scores (already in totalGrade)
      double points = calculatePoints(course.totalGrade);
      totalWeightedPoints += points * course.credits;
      totalCredits += course.credits;
    }

    if (totalCredits == 0) return 0.0;
    return totalWeightedPoints / totalCredits;
  }

  /// Calculates the maximum possible GPA (assuming all pending work gets 100%).
  static double calculateMaxGPA(List<Course> courses) {
    double totalWeightedPoints = 0.0;
    int totalCredits = 0;

    for (var course in courses) {
      if (course.isPassFail) continue;
      
      double maxPossibleGrade = course.totalPotential;
      double points = calculatePoints(maxPossibleGrade);
      totalWeightedPoints += points * course.credits;
      totalCredits += course.credits;
    }

    if (totalCredits == 0) return 0.0;
    return totalWeightedPoints / totalCredits;
  }
}
