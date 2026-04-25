import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widget_service.dart';
import 'task_model.dart';
import 'storage_service.dart';
import 'course_model.dart';
import 'gpa_utils.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Task> _allTasks = [];
  List<Course> _allCourses = [];
  String? _activeSemesterId;
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
    final activeId = await StorageService.loadActiveSemesterId();
    setState(() {
      _allTasks = tasks;
      _allCourses = courses;
      _activeSemesterId = activeId;
    });
    // Sync to widgets
    WidgetService.updateAllWidgets();
  }

  Future<void> _showSyncLogDialog() async {
    String logText = "Starting Widget Sync Debug...\n";

    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString('active_semester');
      logText += "Active Semester ID: $activeId\n";

      await WidgetService.updateAllWidgets();
      logText += "updateAllWidgets() completed.\n";

      // Test retrieval directly from HomeWidget
      final nextClassName = await HomeWidget.getWidgetData<String>('next_class_name');
      final taskCount = await HomeWidget.getWidgetData<int>('task_count');
      final taskTitle = await HomeWidget.getWidgetData<String>('next_task_title');

      logText += "\nData supposedly in UserDefaults:\n";
      logText += "next_class_name: $nextClassName\n";
      logText += "task_count: $taskCount\n";
      logText += "next_task_title: $taskTitle\n";

    } catch (e) {
      logText += "\nERROR: $e\n";
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Widget Sync Log'),
        content: SingleChildScrollView(child: Text(logText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      )
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm:ss a').format(GPAUtils.getMalaysiaTime());
        });
      }
    });
  }

  _NextClass? _getNextClass() {
    final now = GPAUtils.getMalaysiaTime();
    final currentDay = now.weekday;
    final currentTimeMinutes = now.hour * 60 + now.minute;

    List<_NextClass> allSlots = [];
    for (var course in _allCourses) {
      if (course.semesterId != _activeSemesterId) continue;
      if (course.lectureTime != null) {
        allSlots.add(_NextClass.fromParts(course, 'Lecture', course.lectureTime!, course.lectureRoom));
      }
      if (course.hasTutorial && course.tutorialTime != null) {
        allSlots.add(_NextClass.fromParts(course, 'Tutorial', course.tutorialTime!, course.tutorialRoom));
      }
      if (course.hasLab && course.labTime != null) {
        allSlots.add(_NextClass.fromParts(course, 'Lab', course.labTime!, course.labRoom));
      }
    }

    if (allSlots.isEmpty) return null;

    allSlots.sort((a, b) {
      int diffA = (a.day - currentDay) * 1440 + (a.timeMinutes - currentTimeMinutes);
      if (diffA < 0) diffA += 7 * 1440;
      int diffB = (b.day - currentDay) * 1440 + (b.timeMinutes - currentTimeMinutes);
      if (diffB < 0) diffB += 7 * 1440;
      return diffA.compareTo(diffB);
    });

    return allSlots.first;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _allCourses.where((c) => c.semesterId == _activeSemesterId).toList();
    final filteredTasks = _allTasks.where((t) => t.semesterId == _activeSemesterId).toList();

    final allItems = <_DashboardItem>[];
    for (var course in filteredCourses) {
      for (var assessment in course.assessments) {
        allItems.add(_DashboardItem.fromAssessment(assessment, course));
      }
    }
    for (var task in filteredTasks) {
      allItems.add(_DashboardItem.fromTask(task));
    }

    final incompleteItems = allItems.where((i) => !i.isCompleted).toList();
    incompleteItems.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });

    final nextClass = _getNextClass();

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniTask Dashboard'),
        actions: [
          IconButton(onPressed: _showSyncLogDialog, icon: const Icon(Icons.bug_report, color: Colors.orange)),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildNextClassWidget(nextClass),
            const SizedBox(height: 16),
            _buildGPACard(filteredCourses),
            const SizedBox(height: 16),
            _buildClockWidget(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Tasks', style: Theme.of(context).textTheme.titleLarge),
                Text('${incompleteItems.length} Pending', style: const TextStyle(color: Colors.cyanAccent)),
              ],
            ),
            const SizedBox(height: 10),
            if (incompleteItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No active tasks. Free time!', style: TextStyle(color: Colors.grey)),
              )
            else
              ...incompleteItems.map((item) => _buildTaskItem(item)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildGPACard(List<Course> courses) {
    if (courses.isEmpty) return const SizedBox.shrink();

    final currentGPA = GPAUtils.calculateCurrentGPA(courses);
    final minGPA = GPAUtils.calculateMinGPA(courses);
    final maxGPA = GPAUtils.calculateMaxGPA(courses);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Academic Standing', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current GPA', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(currentGPA.toStringAsFixed(2), style: const TextStyle(color: Colors.cyanAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('Min: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(minGPA.toStringAsFixed(2), style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Max: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(maxGPA.toStringAsFixed(2), style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Predictive range based on pending work', style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    DateTime? tempDeadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Task Name')),
              const SizedBox(height: 16),
              ListTile(
                title: Text(tempDeadline == null ? 'Set Deadline' : DateFormat('MMM d, h:mm a').format(tempDeadline!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: GPAUtils.getMalaysiaTime(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setDialogState(() {
                        tempDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newTask = Task(
                    name: nameController.text,
                    deadline: tempDeadline,
                    semesterId: _activeSemesterId,
                  );
                  setState(() {
                    _allTasks.add(newTask);
                  });
                  StorageService.saveTasks(_allTasks);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextClassWidget(_NextClass? next) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: next == null
          ? const Center(child: Text('No Upcoming Classes', style: TextStyle(color: Colors.white, fontSize: 18)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Next Class', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text(next.type, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(next.courseName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(next.timeStr, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(width: 16),
                    const Icon(Icons.room, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(next.room ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildClockWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Malaysia Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(_currentTime.isEmpty ? '--:--:--' : _currentTime.split(' ')[0],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(_DashboardItem item) {
    final now = GPAUtils.getMalaysiaTime();
    bool isUrgent = false;
    if (!item.isCompleted && item.deadline != null) {
      final diff = item.deadline!.difference(now);
      if (diff.inHours < 24 && diff.inHours >= 0) isUrgent = true;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent ? const BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: Checkbox(value: item.isCompleted, onChanged: (val) => _toggleItemCompletion(item)),
        title: Text(item.title, style: TextStyle(decoration: item.isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Text(item.subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.deadline != null) ...[
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  item.reminderMinutes != null ? Icons.notifications_active : Icons.notifications_outlined,
                  color: item.reminderMinutes != null ? Colors.orangeAccent : Colors.grey,
                  size: 18,
                ),
                onPressed: () => _showReminderDialog(item),
              ),
              const SizedBox(width: 8),
              Text(DateFormat('MMM d, h:mm a').format(item.deadline!),
                  style: TextStyle(color: isUrgent ? Colors.redAccent : Colors.grey, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleItemCompletion(_DashboardItem item) {
    setState(() { item.internalToggle(); });
    if (item.sourceType == _SourceType.assessment) {
      StorageService.saveCourses(_allCourses);
    } else {
      StorageService.saveTasks(_allTasks);
    }
  }

  void _showReminderDialog(_DashboardItem item) {
    int value = 30;
    String unit = 'minutes';
    
    if (item.reminderMinutes != null) {
      if (item.reminderMinutes! % 1440 == 0) {
        unit = 'days';
        value = item.reminderMinutes! ~/ 1440;
      } else if (item.reminderMinutes! % 60 == 0) {
        unit = 'hours';
        value = item.reminderMinutes! ~/ 60;
      } else {
        unit = 'minutes';
        value = item.reminderMinutes!;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Reminder'),
        content: StatefulBuilder(
          builder: (context, setDimState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Remind me before this deadline:'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      onChanged: (v) => value = int.tryParse(v) ?? 0,
                      controller: TextEditingController(text: value.toString()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: unit,
                    onChanged: (v) => setDimState(() => unit = v!),
                    items: ['minutes', 'hours', 'days']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService.cancelNotification(item.id.hashCode);
              setState(() {
                item.setReminder(null);
              });
              if (item.sourceType == _SourceType.assessment) {
                StorageService.saveCourses(_allCourses);
              } else {
                StorageService.saveTasks(_allTasks);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove Reminder', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (item.deadline == null) return;
              
              int totalMinutes = value;
              if (unit == 'hours') totalMinutes *= 60;
              if (unit == 'days') totalMinutes *= 1440;
              
              final scheduledTime = item.deadline!.subtract(Duration(minutes: totalMinutes));
              
              if (scheduledTime.isBefore(DateTime.now())) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Reminder time is in the past!')));
                return;
              }

              await NotificationService.scheduleNotification(
                id: item.id.hashCode,
                title: 'Upcoming: ${item.title}',
                body: '${item.subtitle} is due in $value $unit!',
                scheduledDate: scheduledTime,
              );

              setState(() {
                item.setReminder(totalMinutes);
              });
              if (item.sourceType == _SourceType.assessment) {
                StorageService.saveCourses(_allCourses);
              } else {
                StorageService.saveTasks(_allTasks);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

class _NextClass {
  final String courseName;
  final String type;
  final int day;
  final int timeMinutes;
  final String timeStr;
  final String? room;

  _NextClass({required this.courseName, required this.type, required this.day, required this.timeMinutes, required this.timeStr, this.room});

  factory _NextClass.fromParts(Course course, String type, String timePart, String? room) {
    final parts = timePart.split(' ');
    final day = int.parse(parts[0]);
    final tParts = parts[1].split(':');
    final h = int.parse(tParts[0]);
    final m = int.parse(tParts[1]);
    
    final tod = TimeOfDay(hour: h, minute: m);
    final timeStr = '${tod.hourOfPeriod}:${tod.minute.toString().padLeft(2, '0')} ${tod.period == DayPeriod.am ? 'AM' : 'PM'}';

    return _NextClass(
      courseName: course.name,
      type: type,
      day: day,
      timeMinutes: h * 60 + m,
      timeStr: timeStr,
      room: room,
    );
  }
}

enum _SourceType { assessment, task }

class _DashboardItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime? deadline;
  final _SourceType sourceType;
  final Function() internalToggle;
  final Function(int?) setReminder;
  final bool isCompleted;
  final int? reminderMinutes;

  _DashboardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.deadline,
    required this.sourceType,
    required this.internalToggle,
    required this.setReminder,
    required this.isCompleted,
    this.reminderMinutes,
  });

  factory _DashboardItem.fromAssessment(Assessment a, Course c) {
    return _DashboardItem(
      title: a.title,
      subtitle: '${c.name} (${a.type.name.toUpperCase()})',
      deadline: a.deadline,
      sourceType: _SourceType.assessment,
      isCompleted: a.isCompleted,
      reminderMinutes: a.reminderMinutes,
      internalToggle: () => a.isCompleted = !a.isCompleted,
      setReminder: (mins) => a.reminderMinutes = mins,
      id: a.id,
    );
  }

  factory _DashboardItem.fromTask(Task t) {
    return _DashboardItem(
      title: t.name,
      subtitle: 'Personal Task',
      deadline: t.deadline,
      sourceType: _SourceType.task,
      isCompleted: t.isCompleted,
      reminderMinutes: t.reminderMinutes,
      internalToggle: () => t.isCompleted = !t.isCompleted,
      setReminder: (mins) => t.reminderMinutes = mins,
      id: t.name, // Task uses name as ID for simplicity or should we use hashCode?
    );
  }
}
