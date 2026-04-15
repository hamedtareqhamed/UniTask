import 'package:home_widget/home_widget.dart';
import 'storage_service.dart';
import 'course_model.dart';
import 'gpa_utils.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const String _groupId = 'group.dev.albazeli.unitask';
  static const String _androidWidgetName = 'CountdownWidgetProvider';
  static const String _iosWidgetName = 'WidgetExtension';

  /// Updates the home screen widget with the next class info and top 5 tasks.
  static Future<void> updateAllWidgets() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(_groupId);
      final courses = await StorageService.loadCourses();
      final activeId = await StorageService.loadActiveSemesterId();
      final now = GPAUtils.getMalaysiaTime();
      
      // --- PART 1: NEXT CLASS ---
      final currentDay = now.weekday;
      final currentTimeMinutes = now.hour * 60 + now.minute;

      List<_Slot> allSlots = [];
      for (var course in courses) {
        if (course.semesterId != activeId) continue;
        if (course.lectureTime != null) {
          allSlots.add(_Slot(course, 'Lecture', course.lectureTime!, course.lectureRoom, course.lectureSection));
        }
        if (course.hasTutorial && course.tutorialTime != null) {
          allSlots.add(_Slot(course, 'Tutorial', course.tutorialTime!, course.tutorialRoom, course.tutorialSection));
        }
        if (course.hasLab && course.labTime != null) {
          allSlots.add(_Slot(course, 'Lab', course.labTime!, course.labRoom, course.labSection));
        }
      }

      if (allSlots.isNotEmpty) {
        allSlots.sort((a, b) {
          int diffA = (a.day - currentDay) * 1440 + (a.timeMinutes - currentTimeMinutes);
          if (diffA <= 0) diffA += 7 * 1440;
          int diffB = (b.day - currentDay) * 1440 + (b.timeMinutes - currentTimeMinutes);
          if (diffB <= 0) diffB += 7 * 1440;
          return diffA.compareTo(diffB);
        });

        final next = allSlots.first;
        final course = next.course;

        await HomeWidget.saveWidgetData('next_class_name', course.name);
        await HomeWidget.saveWidgetData('next_class_code', course.courseCode ?? '');
        await HomeWidget.saveWidgetData('next_class_type', next.type);
        await HomeWidget.saveWidgetData('next_class_section', next.section);
        await HomeWidget.saveWidgetData('next_class_room', next.room ?? 'TBA');
        await HomeWidget.saveWidgetData('next_class_time', next.timeStr);
        
        int totalMinutes = (next.day - currentDay) * 1440 + (next.timeMinutes - currentTimeMinutes);
        if (totalMinutes <= 0) totalMinutes += 7 * 1440;
        await HomeWidget.saveWidgetData('next_class_countdown', _formatCountdown(totalMinutes));
      } else {
        await HomeWidget.saveWidgetData('next_class_name', 'No Classes');
        await HomeWidget.saveWidgetData('next_class_time', '');
      }

      // --- PART 2: UPCOMING TASKS ---
      List<_WidgetTask> allTasks = [];
      for (var course in courses) {
        if (course.semesterId != activeId) continue;
        for (var a in course.assessments) {
          if (!a.isCompleted && a.deadline != null) {
            allTasks.add(_WidgetTask(
              title: a.title,
              subject: course.name,
              code: course.courseCode ?? '',
              deadline: a.deadline!,
              weight: a.weight,
              typeString: a.type.name.toUpperCase(),
            ));
          }
        }
      }

      allTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
      
      if (allTasks.isNotEmpty) {
        final nextTask = allTasks.first;
        final diff = nextTask.deadline.difference(now);
        
        await HomeWidget.saveWidgetData('next_task_title', nextTask.title);
        await HomeWidget.saveWidgetData('next_task_subject', nextTask.subject);
        await HomeWidget.saveWidgetData('next_task_code', nextTask.code);
        await HomeWidget.saveWidgetData('next_task_countdown', _formatDuration(diff));

        // Top 5 Tasks (for large widget)
        final top5Count = allTasks.length > 5 ? 5 : allTasks.length;
        for (int i = 0; i < 5; i++) {
          if (i < top5Count) {
            final t = allTasks[i];
            await HomeWidget.saveWidgetData('task_${i}_title', t.title);
            await HomeWidget.saveWidgetData('task_${i}_subject', t.subject);
            await HomeWidget.saveWidgetData('task_${i}_code', t.code);
            await HomeWidget.saveWidgetData('task_${i}_time', _formatDateShort(t.deadline));
            await HomeWidget.saveWidgetData('task_${i}_weight', t.weight > 0 ? '${t.weight.toStringAsFixed(0)}%' : '');
            await HomeWidget.saveWidgetData('task_${i}_type', t.typeString);
          } else {
            await HomeWidget.saveWidgetData('task_${i}_title', '');
            await HomeWidget.saveWidgetData('task_${i}_weight', '');
          }
        }
        await HomeWidget.saveWidgetData('task_count', top5Count);
      } else {
        await HomeWidget.saveWidgetData('next_task_title', 'No Tasks');
        await HomeWidget.saveWidgetData('task_count', 0);
      }

      // Trigger update
      debugPrint('WidgetService: Attempting to update widgets (Android: $_androidWidgetName, iOS: $_iosWidgetName)');
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
      debugPrint('WidgetService: Widget update call successful');
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  static String _formatCountdown(int totalMinutes) {
    if (totalMinutes > 1440) return '${(totalMinutes / 1440).floor()} days';
    if (totalMinutes > 60) return '${(totalMinutes / 60).floor()} hours';
    return '$totalMinutes mins';
  }

  static String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays} days';
    if (d.inHours > 0) return '${d.inHours} hours';
    if (d.inMinutes > 0) return '${d.inMinutes} mins';
    return 'Now';
  }

  static String _formatDateShort(DateTime d) {
    return '${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @Deprecated('Use updateAllWidgets')
  static Future<void> updateNextClassWidget() => updateAllWidgets();
}

class _WidgetTask {
  final String title;
  final String subject;
  final String code;
  final DateTime deadline;
  final double weight;
  final String typeString;

  _WidgetTask({
    required this.title,
    required this.subject,
    required this.code,
    required this.deadline,
    required this.weight,
    required this.typeString,
  });
}

class _Slot {
  final Course course;
  final String type;
  final int day;
  final int timeMinutes;
  final String timeStr;
  final String? room;
  final String? section;

  _Slot(this.course, this.type, String timePart, this.room, this.section)
      : day = int.parse(timePart.split(' ')[0]),
        timeMinutes = int.parse(timePart.split(' ')[1].split(':')[0]) * 60 +
            int.parse(timePart.split(' ')[1].split(':')[1]),
        timeStr = _formatRawTime(timePart.split(' ')[1]);

  static String _formatRawTime(String raw) {
    final t = raw.split(':');
    int h = int.parse(t[0]);
    int m = int.parse(t[1]);
    final period = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} $period';
  }
}
