import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_model.dart';
import 'course_model.dart';
import 'note_model.dart';
import 'semester_model.dart';
import 'widget_service.dart';

/// Service responsible for persistent data storage using SharedPreferences.
///
/// Handles saving and loading of Tasks, Courses, Notes, and Semesters.
class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _coursesKey = 'courses';
  static const String _notesKey = 'notes';
  static const String _semestersKey = 'semesters';
  static const String _activeSemesterKey = 'active_semester';

  // --- Semesters ---

  static Future<void> saveSemesters(List<Semester> semesters) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded =
        semesters.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList(_semestersKey, encoded);
  }

  static Future<List<Semester>> loadSemesters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? encoded = prefs.getStringList(_semestersKey);
      if (encoded == null) return [];
      return encoded.map((s) => Semester.fromMap(jsonDecode(s))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveActiveSemesterId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeSemesterKey);
    } else {
      await prefs.setString(_activeSemesterKey, id);
    }
    await WidgetService.updateNextClassWidget();
  }

  static Future<String?> loadActiveSemesterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeSemesterKey);
  }

  // --- Tasks ---

  /// Saves the list of [Task] objects to local storage.
  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedTasks =
        tasks.map((task) => jsonEncode(task.toMap())).toList();
    await prefs.setStringList(_tasksKey, encodedTasks);
  }

  /// Loads the list of [Task] objects from local storage.
  /// Returns an empty list if no data is found or if an error occurs.
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

  // --- Courses ---

  /// Saves the list of [Course] objects to local storage.
  static Future<void> saveCourses(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedCourses =
        courses.map((course) => jsonEncode(course.toMap())).toList();
    await prefs.setStringList(_coursesKey, encodedCourses);
    await WidgetService.updateNextClassWidget();
  }

  /// Loads the list of [Course] objects from local storage.
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

  // --- Notes ---

  /// Saves the list of [Note] objects to local storage.
  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedNotes =
        notes.map((note) => jsonEncode(note.toMap())).toList();
    await prefs.setStringList(_notesKey, encodedNotes);
  }

  /// Loads the list of [Note] objects from local storage.
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

