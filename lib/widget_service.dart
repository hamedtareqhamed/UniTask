import 'package:home_widget/home_widget.dart';
import 'storage_service.dart';
import 'course_model.dart';
import 'gpa_utils.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const String _groupId = 'group.dev.albazeli.unitask';
  static const String _androidWidgetName = 'CountdownWidgetProvider';
  static const String _iosWidgetName = 'ClassWidget';

  /// Updates the home screen widget with the next class info.
  static Future<void> updateNextClassWidget() async {
    if (kIsWeb) return; // home_widget not supported on web
    try {
      await HomeWidget.setAppGroupId(_groupId);
      final courses = await StorageService.loadCourses();
      final activeId = await StorageService.loadActiveSemesterId();
      final now = GPAUtils.getMalaysiaTime();
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

      if (allSlots.isEmpty) {
        await HomeWidget.saveWidgetData('next_class_name', 'No Classes');
        await HomeWidget.saveWidgetData('next_class_time', '');
        await HomeWidget.updateWidget(
          name: _androidWidgetName,
          iOSName: _iosWidgetName,
        );
        return;
      }

      // Find next class
      allSlots.sort((a, b) {
        int diffA = (a.day - currentDay) * 1440 + (a.timeMinutes - currentTimeMinutes);
        if (diffA <= 0) diffA += 7 * 1440; // Skip already passed classes today
        int diffB = (b.day - currentDay) * 1440 + (b.timeMinutes - currentTimeMinutes);
        if (diffB <= 0) diffB += 7 * 1440;
        return diffA.compareTo(diffB);
      });

      final next = allSlots.first;
      final course = next.course;

      // Save data for widgets
      await HomeWidget.saveWidgetData('next_class_name', course.name);
      await HomeWidget.saveWidgetData('next_class_code', course.courseCode ?? '');
      await HomeWidget.saveWidgetData('next_class_type', next.type);
      await HomeWidget.saveWidgetData('next_class_section', next.section ?? '');
      await HomeWidget.saveWidgetData('next_class_room', next.room ?? 'TBA');
      await HomeWidget.saveWidgetData('next_class_time', next.timeStr);
      
      // Calculate countdown string (simplified for widget)
      int totalMinutes = (next.day - currentDay) * 1440 + (next.timeMinutes - currentTimeMinutes);
      if (totalMinutes <= 0) totalMinutes += 7 * 1440;
      
      String countdown = '';
      if (totalMinutes > 1440) {
        countdown = '${(totalMinutes / 1440).floor()} days';
      } else if (totalMinutes > 60) {
        countdown = '${(totalMinutes / 60).floor()} hours';
      } else {
        countdown = '$totalMinutes mins';
      }
      await HomeWidget.saveWidgetData('next_class_countdown', countdown);

      // Trigger update
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
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
