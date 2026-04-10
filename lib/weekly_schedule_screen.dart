import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
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

    int minH = 24; 
    int maxH = 0;
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

    if (days.isEmpty) {
      _startHour = 8;
      _endHour = 18;
      _activeDays = [1, 2, 3, 4, 5];
    } else {
      _startHour = minH;
      _endHour = maxH;
      _activeDays = days.toList()..sort();
    }
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
          // Reverted row height to fit the screen without scroll
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

  void _showCourseDetails(Course course, String type, String? room, String? section, int duration, int hour) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: course.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.class_, color: course.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.courseCode ?? 'N/A', style: TextStyle(color: course.color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text(course.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            _buildDetailRow(Icons.type_specimen, 'Session Type', '$type ${section != null ? "($section)" : ""}'),
            _buildDetailRow(Icons.room, 'Location', room ?? 'TBA'),
            _buildDetailRow(Icons.access_time, 'Schedule', '${_formatHour(hour)} ($duration mins)'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: course.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
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

    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: height - 1, 
      child: GestureDetector(
        onTap: () => _showCourseDetails(course, type, room, sectionCode, durationMinutes, hour),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: course.color.withValues(alpha: 0.4), // Darker but more saturated
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: Colors.white, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Combined Course Code + Session Type on top
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      course.courseCode ?? '',
                      style: TextStyle(fontSize: subSize * 0.9, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: course.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(fontSize: subSize * 0.9, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              // Full name below them (using marquee if too long)
              SizedBox(
                height: titleSize * 0.8,
                child: _buildMarqueeIfNeeded(course.name, titleSize * 0.7, Colors.white, false),
              ),
              const Spacer(flex: 1),
              // Room Code line
              SizedBox(
                height: subSize * 1.2,
                child: _buildMarqueeIfNeeded(room ?? 'TBA', subSize, Colors.white, false),
              ),
              const SizedBox(height: 1),
              // Time line
              Text(
                _formatHour(hour), 
                style: TextStyle(fontSize: subSize, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarqueeIfNeeded(String text, double fontSize, Color color, bool bold) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color);
        final span = TextSpan(text: text, style: textStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();

        if (tp.width > constraints.maxWidth) {
          return Marquee(
            text: text,
            style: textStyle,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 20.0,
            velocity: 30.0,
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 0.0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          );
        } else {
          return Text(text, style: textStyle, overflow: TextOverflow.ellipsis);
        }
      },
    );
  }
}
