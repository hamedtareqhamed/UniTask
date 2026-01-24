import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'course_model.dart';
import 'storage_service.dart';
import 'note_model.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final VoidCallback onCourseUpdated; // Callback to refresh parent screen

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.onCourseUpdated,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Course _course;
  List<Note> _courseNotes = [];

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final allNotes = await StorageService.loadNotes();
    setState(() {
      _courseNotes = allNotes.where((n) => n.courseId == _course.id).toList();
    });
  }

  void _saveCourse() {
    StorageService.loadCourses().then((courses) {
      final index = courses.indexWhere((c) => c.id == _course.id);
      if (index != -1) {
        courses[index] = _course;
        StorageService.saveCourses(courses);
        widget.onCourseUpdated();
        setState(() {});
      }
    });
  }

  void _addNote() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newNote = Note(
                  id: DateTime.now().toString(),
                  title: titleController.text,
                  content: contentController.text,
                  date: DateTime.now(),
                  courseId: _course.id,
                );

                final allNotes = await StorageService.loadNotes();
                allNotes.add(newNote);
                await StorageService.saveNotes(allNotes);

                _loadNotes();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(Note note) async {
    final allNotes = await StorageService.loadNotes();
    allNotes.removeWhere((n) => n.id == note.id);
    await StorageService.saveNotes(allNotes);
    _loadNotes();
  }

  void _showAssessmentDialog({Assessment? assessment}) {
    final titleController = TextEditingController(text: assessment?.title);
    final scoreController = TextEditingController(
      text: assessment?.score?.toString() ?? '',
    );
    final maxScoreController = TextEditingController(
      text: assessment?.maxScore.toString(),
    );
    final weightController = TextEditingController(
      text: assessment?.weight.toString(),
    );

    AssessmentType selectedType = assessment?.type ?? AssessmentType.quiz;
    AssessmentCategory selectedCategory =
        assessment?.category ?? AssessmentCategory.coursework;
    DateTime? selectedDeadline = assessment?.deadline;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assessment == null ? 'Add Assessment' : 'Edit Assessment'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  DropdownButton<AssessmentType>(
                    value: selectedType,
                    isExpanded: true,
                    onChanged: (val) =>
                        setDialogState(() => selectedType = val!),
                    items: AssessmentType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                  ),
                  DropdownButton<AssessmentCategory>(
                    value: selectedCategory,
                    isExpanded: true,
                    onChanged: (val) =>
                        setDialogState(() => selectedCategory = val!),
                    items: AssessmentCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c == AssessmentCategory.coursework
                                  ? 'Coursework'
                                  : 'Final/Project',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  TextField(
                    controller: scoreController,
                    decoration: const InputDecoration(
                      labelText: 'Score Acquired (Leave empty if ungraded)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: maxScoreController,
                    decoration: const InputDecoration(labelText: 'Max Score'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: 'Points'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDeadline == null
                              ? 'No Deadline'
                              : 'Due: ${DateFormat('MMM d, h:mm a').format(selectedDeadline!)}',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDeadline ?? DateTime.now(),
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
                              setDialogState(() {
                                selectedDeadline = DateTime(
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
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final scoreText = scoreController.text.trim();
              final newScore = scoreText.isEmpty
                  ? null
                  : double.tryParse(scoreText);
              final newMaxScore =
                  double.tryParse(maxScoreController.text) ?? 100;
              final newWeight = double.tryParse(weightController.text) ?? 0;

              if (assessment == null) {
                // Add new
                final newAssessment = Assessment(
                  id: DateTime.now().toString(),
                  title: titleController.text,
                  type: selectedType,
                  category: selectedCategory,
                  score: newScore,
                  maxScore: newMaxScore,
                  weight: newWeight,
                  deadline: selectedDeadline,
                );
                _course.assessments.add(newAssessment);
              } else {
                // Edit existing
                setState(() {
                  assessment.title = titleController.text;
                  assessment.type = selectedType;
                  assessment.category = selectedCategory;
                  assessment.score = newScore;
                  assessment.maxScore = newMaxScore;
                  assessment.weight = newWeight;
                  assessment.deadline = selectedDeadline;
                });
              }
              _saveCourse();
              Navigator.pop(context);
            },
            child: Text(assessment == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteAssessment(Assessment assessment) {
    setState(() {
      _course.assessments.remove(assessment);
    });
    _saveCourse();
  }

  Widget _buildOverviewTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Summary
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(children: [_buildSummaryCard()]),
                  ),
                ),
                const SizedBox(width: 20),
                // Right Side: Assessments
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildAssessmentHeader(),
                      Expanded(
                        child: ListView(
                          children: _course.assessments
                              .map(_buildAssessmentCard)
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildAssessmentHeader(),
              ..._course.assessments.map(_buildAssessmentCard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Total Grade', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${_course.totalGrade.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _course.isPassed
                    ? Colors.green
                    : (_course.isImpossibleToPass ? Colors.red : Colors.orange),
              ),
            ),
            Text(
              _course.isPassed
                  ? 'PASSED'
                  : (_course.isImpossibleToPass ? 'FAILED' : 'IN PROGRESS'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _course.isPassed
                    ? Colors.green
                    : (_course.isImpossibleToPass ? Colors.red : Colors.orange),
              ),
            ),
            const Divider(),
            _buildChartRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Assessments', style: Theme.of(context).textTheme.headlineSmall),
        IconButton(
          onPressed: () => _showAssessmentDialog(),
          icon: const Icon(Icons.add_circle, color: Colors.teal, size: 30),
        ),
      ],
    );
  }

  Widget _buildAssessmentCard(Assessment a) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          a.category == AssessmentCategory.coursework
              ? Icons.assignment
              : Icons.school,
          color: Colors.teal,
        ),
        title: Text(a.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${a.type.name.toUpperCase()} • Points: ${a.weight}'),
            if (a.deadline != null)
              Text(
                'Due: ${DateFormat('MMM d, h:mm a').format(a.deadline!)}',
                style: TextStyle(
                  color: a.deadline!.isBefore(DateTime.now())
                      ? Colors.red
                      : Colors.grey,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              a.score == null
                  ? '- / ${a.maxScore}'
                  : '${a.score}/${a.maxScore}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: a.score == null ? Colors.grey : null,
              ),
            ),
            IconButton(
              onPressed: () => _showAssessmentDialog(assessment: a),
              icon: const Icon(Icons.edit, color: Colors.blue),
            ),
            IconButton(
              onPressed: () => _deleteAssessment(a),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    if (_courseNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No notes for this course yet.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNote,
              icon: const Icon(Icons.add),
              label: const Text('Add Note'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        mini: true,
        child: const Icon(Icons.add),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _courseNotes.length,
        itemBuilder: (context, index) {
          final note = _courseNotes[index];
          return Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: InkWell(
              onTap: () {
                // Edit note logic could go here
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => _deleteNote(note),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        note.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d').format(note.date),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartRow() {
    final cwBreakdown = _course.getBreakdown(AssessmentCategory.coursework);
    final finalBreakdown = _course.getBreakdown(
      AssessmentCategory.finalProject,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ScoreDistributionChart(
          title: 'Coursework',
          acquired: cwBreakdown['acquired']!,
          lost: cwBreakdown['lost']!,
          pending: cwBreakdown['pending']!,
          total: _course.courseworkWeight,
          isSecured: _course.isCourseworkSecured,
        ),
        ScoreDistributionChart(
          title: 'Final/Project',
          acquired: finalBreakdown['acquired']!,
          lost: finalBreakdown['lost']!,
          pending: finalBreakdown['pending']!,
          total: _course.finalWeight,
          isSecured: _course.isFinalSecured,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_course.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildOverviewTab(), _buildNotesTab()]),
      ),
    );
  }
}

class ScoreDistributionChart extends StatelessWidget {
  final String title;
  final double acquired;
  final double lost;
  final double pending;
  final double total;
  final bool isSecured;

  const ScoreDistributionChart({
    super.key,
    required this.title,
    required this.acquired,
    required this.lost,
    required this.pending,
    required this.total,
    required this.isSecured,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isSecured) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SECURED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _ScoreDistributionPainter(
              acquired: acquired,
              lost: lost,
              pending: pending,
              total: total,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${acquired.toStringAsFixed(1)} / ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Pending: ${pending.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  Text(
                    'Lost: ${lost.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.red, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreDistributionPainter extends CustomPainter {
  final double acquired;
  final double lost;
  final double pending;
  final double total;

  _ScoreDistributionPainter({
    required this.acquired,
    required this.lost,
    required this.pending,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 12.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..strokeCap = StrokeCap.round;

    double startAngle = -3.14159 / 2; // Start from top

    // Draw Background (Grey/Pending)
    paint.color = Colors.grey.withValues(alpha: 0.2);
    canvas.drawArc(rect, 0, 2 * 3.14159, false, paint);

    // Draw Acquired (Green) - Gradient
    final acquiredSweep = (acquired / total) * 2 * 3.14159;
    paint.color = const Color(0xFF4CAF50); // Vibrant Green
    if (acquiredSweep > 0) {
      canvas.drawArc(rect, startAngle, acquiredSweep, false, paint);
      startAngle += acquiredSweep;
    }

    // Draw Lost (Red)
    final lostSweep = (lost / total) * 2 * 3.14159;
    paint.color = const Color(0xFFE53935); // Vibrant Red
    if (lostSweep > 0) {
      canvas.drawArc(rect, startAngle, lostSweep, false, paint);
      startAngle += lostSweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
