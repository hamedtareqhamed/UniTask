import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'course_model.dart';
import 'semester_model.dart';
import 'storage_service.dart';
import 'gpa_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Course> _courses = [];
  Semester? _activeSemester;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = GPAUtils.getMalaysiaTime();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    final courses = await StorageService.loadCourses();
    final semesters = await StorageService.loadSemesters();
    final activeId = await StorageService.loadActiveSemesterId();
    
    setState(() {
      _courses = courses;
      if (activeId != null) {
        _activeSemester = semesters.firstWhere((s) => s.id == activeId, orElse: () => semesters.first);
      }
    });
  }

  List<Assessment> _getAssessmentsForDay(DateTime day) {
    List<Assessment> assessments = [];
    for (var course in _courses) {
      for (var assessment in course.assessments) {
        if (assessment.deadline != null && isSameDay(assessment.deadline, day)) {
          assessments.add(assessment);
        }
      }
    }
    return assessments;
  }

  void _onTodayPressed() {
    setState(() {
      _focusedDay = GPAUtils.getMalaysiaTime();
      _selectedDay = _focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Deep macOS-style background
      body: SafeArea(
        child: Column(
          children: [
            _buildCalendarHeader(),
            const Divider(height: 1, color: Colors.white10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight - 40;
                  final dynamicRowHeight = availableHeight / 6;

                  // Week number logic
                  final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
                  final dayOffset = (firstDayOfMonth.weekday - 1); // 0=Mon, 6=Sun
                  final visualStartDay = firstDayOfMonth.subtract(Duration(days: dayOffset));

                  return Row(
                    children: [
                      // Week Number Sidebar
                      SizedBox(
                        width: 32,
                        child: Column(
                          children: [
                            const SizedBox(height: 40), // Header offset matches daysOfWeekHeight
                            ...List.generate(6, (index) {
                              final rowDate = visualStartDay.add(Duration(days: index * 7));
                              int weekNum = -1;
                              if (_activeSemester != null) {
                                weekNum = (rowDate.difference(_activeSemester!.startDate).inDays / 7).floor() + 1;
                              }
                              
                              return Container(
                                height: dynamicRowHeight,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                                ),
                                child: Text(
                                  weekNum > 0 && weekNum < 20 ? 'W$weekNum' : '',
                                  style: const TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      // Calendar Grid
                      Expanded(
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          headerVisible: false,
                          daysOfWeekHeight: 40,
                          rowHeight: dynamicRowHeight, 
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: true,
                            defaultTextStyle: TextStyle(color: Colors.white70),
                            weekendTextStyle: TextStyle(color: Colors.white54),
                            holidayTextStyle: TextStyle(color: Colors.white),
                            cellMargin: EdgeInsets.zero,
                            cellPadding: EdgeInsets.zero,
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12),
                            weekendStyle: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            setState(() => _focusedDay = focusedDay);
                          },
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) => _buildGridCell(day, isOutside: false),
                            outsideBuilder: (context, day, focusedDay) => _buildGridCell(day, isOutside: true),
                            selectedBuilder: (context, day, focusedDay) => _buildGridCell(day, isSelected: true),
                            todayBuilder: (context, day, focusedDay) => _buildGridCell(day, isToday: true),
                            markerBuilder: (context, day, events) {
                              final assessments = _getAssessmentsForDay(day);
                              if (assessments.isEmpty) return null;
                              return _buildEventPills(assessments, dynamicRowHeight);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM').format(_focusedDay),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('yyyy').format(_focusedDay),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white70),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20, color: Colors.white70),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                ),
                TextButton(
                  onPressed: _onTodayPressed,
                  child: const Text('Today', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20, color: Colors.white70),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(DateTime day, {bool isSelected = false, bool isToday = false, bool isOutside = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
        color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.05) : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 6,
            child: Text(
              day.day.toString(),
              style: TextStyle(
                color: isToday ? Colors.cyanAccent : (isOutside ? Colors.white24 : Colors.white70),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPills(List<Assessment> assessments, double rowHeight) {
    return Positioned(
      left: 2,
      right: 2,
      top: rowHeight * 0.35, // Moved down to avoid covering day number
      child: Column(
        children: assessments.take(3).map((a) {
          final course = _courses.firstWhere(
            (c) => c.assessments.any((as) => as.id == a.id),
            orElse: () => _courses.first,
          );
          
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: course.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border(left: BorderSide(color: course.color, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: course.color.withValues(alpha: 0.9)),
                      children: [
                        TextSpan(
                          text: (course.courseCode != null && course.courseCode!.isNotEmpty) 
                                ? course.courseCode! 
                                : (course.name.length > 6 ? course.name.substring(0, 6) : course.name), 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 8)
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(text: a.title),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                  decoration: BoxDecoration(
                    color: course.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${a.weight.toStringAsFixed(0)}%',
                    style: TextStyle(color: course.color, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
