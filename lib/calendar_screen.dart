import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'course_model.dart';
import 'storage_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Course> _courses = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    final courses = await StorageService.loadCourses();
    setState(() {
      _courses = courses;
    });
  }

  List<Assessment> _getAssessmentsForDay(DateTime day) {
    List<Assessment> assessments = [];
    for (var course in _courses) {
      for (var assessment in course.assessments) {
        if (assessment.deadline != null &&
            isSameDay(assessment.deadline, day)) {
          assessments.add(assessment);
        }
      }
    }
    return assessments;
  }

  bool _isBusyWindow(DateTime day) {
    int count = 0;
    for (int i = 0; i < 5; i++) {
      final targetDay = day.add(Duration(days: i));
      for (var course in _courses) {
        for (var assessment in course.assessments) {
          if (assessment.deadline != null &&
              isSameDay(assessment.deadline, targetDay)) {
            count++;
          }
        }
      }
    }
    return count >= 5;
  }

  Color? _getDayColor(DateTime day) {
    if (_isBusyWindow(day)) {
      return Colors.red.withValues(alpha: 0.3);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedAssessments = _selectedDay == null
        ? <Assessment>[]
        : _getAssessmentsForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(title: const Text('Academic Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, events) => Container(
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  date.day.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              todayBuilder: (context, date, events) => Container(
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  date.day.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              markerBuilder: (context, day, events) {
                final assessments = _getAssessmentsForDay(day);
                if (assessments.isNotEmpty) {
                  return Positioned(
                    bottom: 6,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return null;
              },
              defaultBuilder: (context, day, focusedDay) {
                final color = _getDayColor(day);
                if (color != null) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12.0), // Rounded rect
                    ),
                    child: Text(
                      day.day.toString(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: selectedAssessments.isEmpty
                ? const Center(child: Text('No assessments for this day.'))
                : ListView.builder(
                    itemCount: selectedAssessments.length,
                    itemBuilder: (context, index) {
                      final assessment = selectedAssessments[index];
                      // Find course for this assessment
                      final course = _courses.firstWhere(
                        (c) => c.assessments.any((a) => a.id == assessment.id),
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: course.color.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.event,
                            color: course.color,
                            size: 20,
                          ),
                        ),
                        title: Text(assessment.title),
                        subtitle: Text(
                          '${course.name} • ${DateFormat('h:mm a').format(assessment.deadline!)}',
                        ),
                        trailing: Text(assessment.type.name.toUpperCase()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
