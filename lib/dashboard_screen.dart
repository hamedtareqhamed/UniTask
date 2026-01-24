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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    // 1. Combine Assessments and Tasks into a single list of display items
    final allItems = <_DashboardItem>[];

    // Add Course Assessments
    for (var course in _courses) {
      for (var assessment in course.assessments) {
        allItems.add(_DashboardItem.fromAssessment(assessment, course));
      }
    }

    // Add Non-Course Tasks
    for (var task in _tasks) {
      allItems.add(_DashboardItem.fromTask(task));
    }

    // 2. Separate into Incomplete and Completed
    final incompleteItems = allItems.where((i) => !i.isCompleted).toList();
    final completedItems = allItems.where((i) => i.isCompleted).toList();

    // 3. Sort Incomplete by Deadline (Ascending - Sooner first)
    // Items without deadline go to the end
    incompleteItems.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });

    // 4. Calculate Overall Progress
    final totalItems = allItems.length;
    final completedCount = completedItems.length;
    final progress = totalItems == 0 ? 0.0 : completedCount / totalItems;

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
                      fontFamily: 'Courier',
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
                    bool hasDeadline = allItems.any(
                      (i) => i.deadline != null && isSameDay(i.deadline, day),
                    );

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
                      '$completedCount/$totalItems',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 40),

            // Combined Task List
            if (incompleteItems.isEmpty && completedItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No tasks or assessments yet.'),
              )
            else ...[
              // Incomplete Items
              if (incompleteItems.isNotEmpty) ...[
                Text(
                  'To Do',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                ...incompleteItems.map((item) => _buildTaskItem(item)),
              ],

              // Completed Items
              if (completedItems.isNotEmpty) ...[
                if (incompleteItems.isNotEmpty) const SizedBox(height: 20),
                Text(
                  'Completed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                ...completedItems.map((item) => _buildTaskItem(item)),
              ],
            ],

            const Divider(height: 40),

            // Add Non-Course Task Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Non-Course Task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
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
                      IconButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (date != null) {
                            if (!context.mounted) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                // Store selected deadline in a temporary variable or controller?
                                // For simplicity, let's use a class member or helper
                                _tempSelectedDeadline = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        icon: Icon(
                          Icons.calendar_today,
                          color: _tempSelectedDeadline != null
                              ? Colors.cyanAccent
                              : Colors.grey,
                        ),
                        tooltip: _tempSelectedDeadline != null
                            ? DateFormat(
                                'MMM d, h:mm a',
                              ).format(_tempSelectedDeadline!)
                            : 'Set Deadline',
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addNonCourseTask,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (_tempSelectedDeadline != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Due: ${DateFormat('MMM d, h:mm a').format(_tempSelectedDeadline!)}',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Temporary state for the date picker
  DateTime? _tempSelectedDeadline;

  void _addNonCourseTask() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _tasks.add(
          Task(name: _taskController.text, deadline: _tempSelectedDeadline),
        );
        _taskController.clear();
        _tempSelectedDeadline = null;
      });
      StorageService.saveTasks(_tasks);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Personal Task Added!')));
    }
  }

  Widget _buildTaskItem(_DashboardItem item) {
    final now = DateTime.now();
    bool isUrgent = false;
    if (!item.isCompleted && item.deadline != null) {
      final diff = item.deadline!.difference(now);
      if (diff.inHours < 24 && diff.inHours >= 0) {
        isUrgent = true;
      }
    }

    Widget card = Card(
      elevation: 2,
      color: item.isCompleted
          ? Theme.of(context).cardColor.withValues(alpha: 0.5)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? const BorderSide(color: Colors.redAccent, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (val) {
            _toggleItemCompletion(item);
          },
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.subtitle),
            if (item.deadline != null)
              Text(
                'Due: ${DateFormat('MMM d, h:mm a').format(item.deadline!)}',
                style: TextStyle(
                  color: isUrgent ? Colors.redAccent : Colors.grey,
                  fontSize: 12,
                  fontWeight: isUrgent ? FontWeight.bold : null,
                ),
              ),
          ],
        ),
        trailing: isUrgent
            ? const _GlowingWarningIcon() // Animation Widget
            : null,
      ),
    );

    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: card);
  }

  void _toggleItemCompletion(_DashboardItem item) {
    setState(() {
      item.internalToggle();
    });

    // We need to save the source
    if (item.sourceType == _SourceType.assessment) {
      StorageService.saveCourses(_courses);
    } else {
      StorageService.saveTasks(_tasks);
    }
  }
}

// --- Helper Models & Widgets ---

enum _SourceType { assessment, task }

class _DashboardItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime? deadline;
  final _SourceType sourceType;

  // Mutable references to the original object to toggle state
  final Function() internalToggle;
  final bool Function() getCompleted;

  _DashboardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.deadline,
    required this.sourceType,
    required this.internalToggle,
    required this.getCompleted,
  });

  bool get isCompleted => getCompleted();

  factory _DashboardItem.fromAssessment(Assessment a, Course c) {
    return _DashboardItem(
      id: a.id,
      title: a.title,
      subtitle: '${c.name} (${a.type.name.toUpperCase()})',
      deadline: a.deadline,
      sourceType: _SourceType.assessment,
      getCompleted: () => a.isCompleted,
      internalToggle: () => a.isCompleted = !a.isCompleted,
    );
  }

  factory _DashboardItem.fromTask(Task t) {
    return _DashboardItem(
      id: t.hashCode.toString(),
      title: t.name,
      subtitle: 'Personal Task',
      deadline: t.deadline,
      sourceType: _SourceType.task,
      getCompleted: () => t.isCompleted,
      internalToggle: () => t.isCompleted = !t.isCompleted,
    );
  }
}

class _GlowingWarningIcon extends StatefulWidget {
  const _GlowingWarningIcon();

  @override
  State<_GlowingWarningIcon> createState() => _GlowingWarningIconState();
}

class _GlowingWarningIconState extends State<_GlowingWarningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: _animation.value),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
      },
    );
  }
}
