import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'task_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Names & Bindings
  final List<Task> _tasks = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  // Subprogram: Timer Logic
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
    });
  }

  // Subprogram: Add Task
  void _addTask() {
    // Control Structure: If-else for validation
    if (_formKey.currentState!.validate()) {
      setState(() {
        String name = _taskController.text;
        // Expression: parsing double
        double score = double.tryParse(_scoreController.text) ?? 0.0;

        _tasks.add(Task(name: name, score: score));
        _taskController.clear();
        _scoreController.clear();
      });
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
            // Timer Control
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Session:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _currentTime,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Calendar Widget
            Card(
              elevation: 4,
              child: TableCalendar(
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
                      DataColumn(label: Text('Grade')),
                      DataColumn(label: Text('Action')),
                    ],
                    // Control Structure: Using map() to generate rows
                    rows: _tasks.map((task) {
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
