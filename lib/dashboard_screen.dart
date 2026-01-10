import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'task_model.dart';
import 'storage_service.dart';
import 'course_model.dart';

/// The main Dashboard screen of the application.
///
/// Displays:
/// - Current session digital clock.
/// - Weekly calendar strip with deadline indicators.
/// - Overall progress circular indicator and stats.
/// - List of upcoming deadlines.
/// - Task adding entry form and task list.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Names & Bindings
  List<Task> _tasks = []; // Changed to non-final to allow reassignment
  List<Course> _courses = [];
  String? _selectedCourseId;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await StorageService.loadTasks();
    final courses = await StorageService.loadCourses();
    setState(() {
      _tasks = tasks;
      _courses = courses;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  // --- Subprograms ---

  /// Starts the digital clock timer, updating every second.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
        });
      }
    });
  }

  /// Adds a new task based on form input.
  ///
  /// Validates input, creates a [Task] object, adds it to the list,
  /// and persists the changes.
  void _addTask() {
    // Control Structure: If-else for validation
    if (_formKey.currentState!.validate()) {
      setState(() {
        String name = _taskController.text;
        // Expression: parsing double
        double score = double.tryParse(_scoreController.text) ?? 0.0;

        _tasks.add(Task(name: name, score: score, courseId: _selectedCourseId));
        _taskController.clear();
        _scoreController.clear();
        _selectedCourseId = null;
      });
      StorageService.saveTasks(_tasks); // Save changes
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task Added Successfully!')));
    }
  }

  // Subprogram: Calculate Progress
  double _calculateProgress(int total, int completed) {
    if (total == 0) return 0.0;
    // Expression & Assignment: Progress calculation
    return completed / total;
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    StorageService.saveTasks(_tasks); // Save changes
  }

  List<Map<String, dynamic>> _getUpcomingAssessments() {
    List<Map<String, dynamic>> upcoming = [];
    final now = DateTime.now();
    for (var course in _courses) {
      for (var assessment in course.assessments) {
        if (assessment.deadline != null && assessment.deadline!.isAfter(now)) {
          upcoming.add({'course': course, 'assessment': assessment});
        }
      }
    }
    upcoming.sort((a, b) {
      DateTime d1 = (a['assessment'] as Assessment).deadline!;
      DateTime d2 = (b['assessment'] as Assessment).deadline!;
      return d1.compareTo(d2);
    });
    return upcoming.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Logic for progress
    int completedTasks = _tasks.where((t) => t.isCompleted).length;
    double progress = _calculateProgress(_tasks.length, completedTasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Digital Clock Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E2E2E), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Current Session',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentTime.isEmpty ? '--:--:--' : _currentTime,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Courier', // Or Monospace
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Calendar Strip
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.week,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white70),
                  weekendTextStyle: TextStyle(color: Colors.white70),
                ),
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
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
                    bool hasDeadline = false;
                    for (var course in _courses) {
                      if (course.assessments.any(
                        (a) => a.deadline != null && isSameDay(a.deadline, day),
                      )) {
                        hasDeadline = true;
                        break;
                      }
                    }

                    if (hasDeadline) {
                      return Positioned(
                        bottom: 8,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.cyanAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progress Indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Progress',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}% Completed',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    Text(
                      '$completedTasks/${_tasks.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            // Upcoming Deadlines Section
            if (_courses.any(
              (c) => c.assessments.any(
                (a) =>
                    a.deadline != null && a.deadline!.isAfter(DateTime.now()),
              ),
            )) ...[
              const Divider(height: 40),
              Text(
                'Upcoming Deadlines',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ..._getUpcomingAssessments().map((item) {
                final assessment = item['assessment'] as Assessment;
                final course = item['course'] as Course;
                final deadline = assessment.deadline!;
                final daysLeft = deadline.difference(DateTime.now()).inDays;
                Color statusColor;
                if (daysLeft < 1) {
                  statusColor = Colors.red;
                } else if (daysLeft < 3) {
                  statusColor = Colors.orange;
                } else {
                  statusColor = Colors.green;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: course.color.withValues(alpha: 0.2),
                      child: Icon(
                        assessment.category == AssessmentCategory.coursework
                            ? Icons.assignment
                            : Icons.school,
                        color: course.color,
                        size: 20,
                      ),
                    ),
                    title: Text(assessment.title),
                    subtitle: Text(
                      '${course.name} • ${DateFormat('MMM d').format(deadline)}',
                    ),
                    trailing: Chip(
                      label: Text(
                        daysLeft == 0
                            ? 'Today'
                            : daysLeft == 1
                            ? 'Tomorrow'
                            : 'in $daysLeft days',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: statusColor,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                );
              }),
            ],

            const Divider(height: 40),

            // Form to Add Task
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  if (_courses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Course (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedCourseId,
                        items: _courses.map((course) {
                          return DropdownMenuItem(
                            value: course.id,
                            child: Text(course.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCourseId = value;
                          });
                        },
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _taskController,
                          decoration: const InputDecoration(
                            labelText: 'Task Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter task name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _scoreController,
                          decoration: const InputDecoration(
                            labelText: 'Grade',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addTask,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // DataTable
            if (_tasks.isNotEmpty)
              Card(
                elevation: 2,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Task')),
                      DataColumn(label: Text('Course')),
                      DataColumn(label: Text('Grade')),
                      DataColumn(label: Text('Action')),
                    ],
                    // Control Structure: Using map() to generate rows
                    rows: _tasks.map((task) {
                      final courseName = _courses
                          .firstWhere(
                            (c) => c.id == task.courseId,
                            orElse: () => Course(
                              id: '',
                              name: '-',
                              professor: '',
                              credits: 0,
                              colorValue: 0,
                            ),
                          )
                          .name;
                      return DataRow(
                        cells: <DataCell>[
                          DataCell(
                            Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: task.isCompleted
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          DataCell(Text(task.name)),
                          DataCell(Text(courseName == '-' ? '' : courseName)),
                          DataCell(Text(task.score.toString())),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.done),
                              onPressed: () => _toggleTaskCompletion(task),
                              tooltip: 'Mark as Completed',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: Text('No tasks added yet.')),
              ),
          ],
        ),
      ),
    );
  }
}
