import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_model.dart';
import 'course_model.dart';
import 'note_model.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _coursesKey = 'courses';
  static const String _notesKey = 'notes';

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedTasks = tasks
        .map((task) => jsonEncode(task.toMap()))
        .toList();
    await prefs.setStringList(_tasksKey, encodedTasks);
  }

  static Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? encodedTasks = prefs.getStringList(_tasksKey);

      if (encodedTasks == null) return [];

      return encodedTasks
          .map((taskStr) => Task.fromMap(jsonDecode(taskStr)))
          .toList();
    } catch (e) {
      // Return empty list on error to prevent crash
      return [];
    }
  }

  static Future<void> saveCourses(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedCourses = courses
        .map((course) => jsonEncode(course.toMap()))
        .toList();
    await prefs.setStringList(_coursesKey, encodedCourses);
  }

  static Future<List<Course>> loadCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? encodedCourses = prefs.getStringList(_coursesKey);

      if (encodedCourses == null) return [];

      return encodedCourses
          .map((courseStr) => Course.fromMap(jsonDecode(courseStr)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedNotes = notes
        .map((note) => jsonEncode(note.toMap()))
        .toList();
    await prefs.setStringList(_notesKey, encodedNotes);
  }

  static Future<List<Note>> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? encodedNotes = prefs.getStringList(_notesKey);

      if (encodedNotes == null) return [];

      return encodedNotes
          .map((noteStr) => Note.fromMap(jsonDecode(noteStr)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
