import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Bulk Import JSON format:
  /// {
  ///   "courses": [ { "code": "TSE", "name": "...", "assessments": [...] } ],
  ///   "sections": [ { "className": "DS1D", "courseCode": "TSE", ... } ]
  /// }
  Future<Map<String, int>> bulkImport(String jsonStr) async {
    int coursesAdded = 0;
    int sectionsAdded = 0;
    int assessmentsAdded = 0;

    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);

      // 1. Process Courses
      if (data.containsKey('courses')) {
        for (var course in data['courses']) {
          final String code = course['code'];
          await _firestore.collection('ready_made_courses').doc(code).set({
            'name': course['name'] ?? 'Untitled Course',
            'professor': course['professor'] ?? 'Unknown',
            'credits': course['credits'] ?? 3,
            'courseworkWeight': course['courseworkWeight'] ?? 60.0,
          });
          coursesAdded++;

          // Assessments subcollection
          if (course.containsKey('assessments')) {
            final assessments = _firestore
                .collection('ready_made_courses')
                .doc(code)
                .collection('assessments');
            
            for (int i = 0; i < course['assessments'].length; i++) {
              final a = course['assessments'][i];
              await assessments.doc(i.toString()).set({
                'title': a['title'] ?? 'Assessment',
                'type': a['type'] ?? 'other',
                'category': a['category'] ?? 'coursework',
                'maxScore': a['maxScore'] ?? 10.0,
                'weight': a['weight'] ?? 10.0,
                'deadline': a['deadline'] ?? '',
                'isCompleted': a['isCompleted'] ?? false,
              });
              assessmentsAdded++;
            }
          }
        }
      }

      // 2. Process Sections
      if (data.containsKey('sections')) {
        for (var sec in data['sections']) {
          final String className = sec['className'];
          await _firestore.collection('ready_made_sections').doc(className).set({
            'courseCode': sec['courseCode'] ?? '',
            'lecTime': sec['lecTime'] ?? '',
            'labTime': sec['labTime'] ?? '',
            'lecRoom': sec['lecRoom'] ?? '',
            'labRoom': sec['labRoom'] ?? '',
            'instructor': sec['instructor'] ?? '',
            'credits': sec['credits'] ?? 3,
            'courseworkWeight': sec['courseworkWeight'] ?? 60.0,
          });
          sectionsAdded++;
        }
      }

      return {
        'courses': coursesAdded,
        'sections': sectionsAdded,
        'assessments': assessmentsAdded,
      };
    } catch (e) {
      debugPrint('Admin Bulk Import Error: $e');
      rethrow;
    }
  }

  Future<void> clearCloudData() async {
    // Note: Clearing collections in Firestore is costly/tricky,
    // usually done document by document. For this admin tool, 
    // we just overwrite existing docs. 
  }
}
