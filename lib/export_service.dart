import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import 'course_model.dart';
import 'storage_service.dart';
import 'export_helper.dart' // This is the interface file
    if (dart.library.html) 'export_helper_web.dart'
    if (dart.library.io) 'export_helper_mobile.dart';

class ExportService {
  /// Generates a CSV string for a given course.
  String generateCSVForCourse(Course course) {
    List<List<dynamic>> rows = [];

    // Header info
    rows.add(['Course Name:', course.name]);
    rows.add(['Professor:', course.professor]);
    rows.add(['Credits:', course.credits]);
    rows.add(['Coursework Weight:', '${course.courseworkWeight}%']);
    rows.add(['Final Weight:', '${course.finalWeight}%']);
    rows.add([]); // Empty row
    
    // Table Header
    rows.add([
      'ID',
      'Title',
      'Type',
      'Category',
      'Score',
      'Max Score',
      'Weight (Points)',
      'Deadline',
      'Completed'
    ]);

    // Data rows
    for (var a in course.assessments) {
      rows.add([
        a.id,
        a.title,
        a.type.name,
        a.category.name,
        a.score ?? 'N/A',
        a.maxScore,
        a.weight,
        a.deadline != null ? DateFormat('yyyy-MM-dd HH:mm').format(a.deadline!) : 'N/A',
        a.isCompleted ? 'Yes' : 'No',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exports all course work into a single ZIP file containing CSVs.
  Future<void> exportToZip() async {
    final courses = await StorageService.loadCourses();
    final semesters = await StorageService.loadSemesters();
    
    final archive = Archive();

    for (var course in courses) {
      // Find semester name for folder structure
      String semesterFolderName = "Undefined";
      if (course.semesterId != null) {
        try {
          final sem = semesters.firstWhere(
            (s) => s.id == course.semesterId, 
          );
          semesterFolderName = sem.name;
        } catch (_) {
          semesterFolderName = "Unknown Semester";
        }
      }

      final csvString = generateCSVForCourse(course);
      final bytes = utf8.encode(csvString);
      
      // Clean course name for filename
      final cleanedName = course.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      
      final archiveFile = ArchiveFile(
        '$semesterFolderName/$cleanedName.csv', 
        bytes.length, 
        bytes
      );
      archive.addFile(archiveFile);
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) return;

    final fileName = 'UniTask_Export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.zip';

    // Call the platform-specific helper
    await saveFile(Uint8List.fromList(zipData), fileName);
  }
}
