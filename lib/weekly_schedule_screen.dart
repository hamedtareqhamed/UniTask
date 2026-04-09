import 'package:flutter/material.dart';
import 'course_model.dart';
import 'storage_service.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;

  // Adaptive range parameters
  int _startHour = 8;
  int _endHour = 18;
  List<int> _activeDays = [1, 2, 3, 4, 5]; // 1=Mon, 7=Sun

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final activeId = await StorageService.loadActiveSemesterId();
    final allCourses = await StorageService.loadCourses();
    setState(() {
      _courses = allCourses.where((c) => c.semesterId == activeId).toList();
      _computeRange();
      _isLoading = false;
    });
  }

  void _computeRange() {
    if (_courses.isEmpty) {
      _startHour = 8;
      _endHour = 20; // 8 PM
      _activeDays = [1, 2, 3, 4, 5];
      return;
    }

    int minH = 8; // Default start at 8
    int maxH = 20; // Default end at 8 PM
    Set<int> days = {};

    for (var course in _courses) {
      _scanTime(course.lectureTime, course.lectureDuration, (d, h, eh) {
        days.add(d);
        if (h < minH) minH = h;
        if (eh > maxH) maxH = eh;
      });
      if (course.hasTutorial) {
        _scanTime(course.tutorialTime, course.tutorialDuration, (d, h, eh) {
          days.add(d);
          if (h < minH) minH = h;
          if (eh > maxH) maxH = eh;
        });
      }
      if (course.hasLab) {
        _scanTime(course.labTime, course.labDuration, (d, h, eh) {
          days.add(d);
          if (h < minH) minH = h;
          if (eh > maxH) maxH = eh;
        });
      }
    }

    _startHour = minH;
    _endHour = maxH;
    _activeDays = days.isEmpty ? [1, 2, 3, 4, 5] : (days.toList()..sort());
  }

  void _scanTime(String? timeStr, int duration, Function(int day, int hour, int endHour) onMatch) {
    if (timeStr == null || !timeStr.contains(' ')) return;
    final parts = timeStr.split(' ');
    final day = int.tryParse(parts[0]);
    final timeParts = parts[1].split(':');
    final hour = int.tryParse(timeParts[0]);
    if (day != null && hour != null) {
      final endHour = (hour * 60 + duration + 59) ~/ 60; // Rounded up hour
      onMatch(day, hour, endHour);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final totalHours = _endHour - _startHour;
    final totalDays = _activeDays.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), 
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double timeColumnWidth = 55.0;
          const double headerHeight = 35.0;
          final double availableHeight = constraints.maxHeight - 24; 
          final double rowHeight = (availableHeight - headerHeight) / totalHours;
          final double dayWidth = (constraints.maxWidth - 32 - timeColumnWidth) / totalDays;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time column
                SizedBox(
                  width: timeColumnWidth,
                  child: Column(
                    children: [
                      SizedBox(height: headerHeight), 
                      ...List.generate(totalHours, (index) {
                        final hour = index + _startHour;
                        return Container(
                          height: rowHeight,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            _formatHour(hour),
                            style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Days columns
                ..._activeDays.map((dayIdx) {
                  return SizedBox(
                    width: dayWidth,
                    child: Column(
                      children: [
                        Container(
                          height: headerHeight,
                          alignment: Alignment.center,
                          child: Text(
                            dayNames[dayIdx - 1].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Colors.white54, letterSpacing: 1.0),
                          ),
                        ),
                        Stack(
                          children: [
                            Column(
                              children: List.generate(totalHours, (index) => Container(
                                height: rowHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.02), width: 0.5),
                                ),
                              )),
                            ),
                            ..._buildClassesForDay(dayIdx, rowHeight),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  List<Widget> _buildClassesForDay(int day, double rowHeight) {
    List<Widget> widgets = [];
    for (var course in _courses) {
      if (course.lectureTime != null && course.lectureTime!.startsWith('$day ')) {
        widgets.add(_buildClassBox(course, course.lectureTime!, course.lectureRoom, course.lectureSection, 'Lecture', course.lectureDuration, rowHeight));
      }
      if (course.hasTutorial && course.tutorialTime != null && course.tutorialTime!.startsWith('$day ')) {
        widgets.add(_buildClassBox(course, course.tutorialTime!, course.tutorialRoom, course.tutorialSection, 'Tutorial', course.tutorialDuration, rowHeight));
      }
      if (course.hasLab && course.labTime != null && course.labTime!.startsWith('$day ')) {
        widgets.add(_buildClassBox(course, course.labTime!, course.labRoom, course.labSection, 'Lab', course.labDuration, rowHeight));
      }
    }
    return widgets;
  }

  Widget _buildClassBox(Course course, String timeStr, String? room, String? sectionCode, String type, int durationMinutes, double rowHeight) {
    final parts = timeStr.split(' ');
    final timeParts = parts[1].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Dynamic Font Sizes based on rowHeight - increased for better space filling
    final double titleSize = (rowHeight * 0.25).clamp(10.0, 24.0);
    final double subSize = (rowHeight * 0.12).clamp(7.0, 14.0);

    // Position relative to _startHour
    final startMinutes = (hour * 60 + minute) - (_startHour * 60);
    final top = (startMinutes / 60) * rowHeight; 
    final height = (durationMinutes / 60) * rowHeight;

    String typeLabel = type.substring(0, 3).toUpperCase();
    if (sectionCode != null && sectionCode.isNotEmpty) {
      typeLabel += ' - $sectionCode';
    }

    String displayTitle = (course.courseCode != null && course.courseCode!.isNotEmpty) 
        ? course.courseCode! 
        : course.name;

    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: height - 1, 
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: course.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: course.color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayTitle, 
                      style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: course.color),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: course.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(fontSize: subSize * 0.8, fontWeight: FontWeight.w900, color: course.color),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room ?? 'TBA', 
                    style: TextStyle(fontSize: subSize, color: course.color.withValues(alpha: 0.8), fontWeight: FontWeight.w500), 
                    overflow: TextOverflow.ellipsis
                  ),
                ),
                Text(
                  _formatHour(hour), 
                  style: TextStyle(fontSize: subSize, fontWeight: FontWeight.bold, color: course.color.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
