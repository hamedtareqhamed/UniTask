import 'package:flutter/material.dart';
import 'course_model.dart';
import 'semester_model.dart';
import 'storage_service.dart';
import 'course_detail_screen.dart';
import 'ready_made_service.dart';
import 'semester_management_screen.dart';
import 'backup_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  List<Semester> _semesters = [];
  String? _activeSemesterId;

  final ReadyMadeService _readyMadeService = ReadyMadeService();

  // Controllers and State Variables
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _creditsController = TextEditingController();
  
  // Weekly Schedule Controllers
  final _lectureRoomController = TextEditingController();
  final _lectureSecController = TextEditingController();
  final _tutorialRoomController = TextEditingController();
  final _tutorialSecController = TextEditingController();
  final _labRoomController = TextEditingController();
  final _labSecController = TextEditingController();
  
  int _lectureDay = 1;
  TimeOfDay _lectureTime = const TimeOfDay(hour: 10, minute: 0);
  int _lectureDuration = 120;

  bool _hasTutorial = false;
  int _tutorialDay = 1;
  TimeOfDay _tutorialTime = const TimeOfDay(hour: 12, minute: 0);
  int _tutorialDuration = 120;

  bool _hasLab = false;
  int _labDay = 1;
  TimeOfDay _labTime = const TimeOfDay(hour: 14, minute: 0);
  int _labDuration = 120;

  String? _selectedSemesterId;

  double _courseworkWeight = 60.0;
  double _finalWeight = 40.0;
  bool _isPassFail = false;
  int _selectedColor = Colors.blue.toARGB32();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _creditsController.dispose();
    _lectureRoomController.dispose();
    _lectureSecController.dispose();
    _tutorialRoomController.dispose();
    _tutorialSecController.dispose();
    _labRoomController.dispose();
    _labSecController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final courses = await StorageService.loadCourses();
    final semesters = await StorageService.loadSemesters();
    final activeId = await StorageService.loadActiveSemesterId();
    setState(() {
      _allCourses = courses;
      _semesters = semesters;
      _activeSemesterId = activeId;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredCourses = _allCourses.where((c) => c.semesterId == _activeSemesterId).toList();
    });
  }

  void _showImportDialog() async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final entries = await _readyMadeService.loadSections();
    if (!mounted) return;
    Navigator.pop(context); // Close loading indicator

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No ready-made courses found in Cloud templates.')));
      return;
    }

    final uniqueCourseCodes = entries.map((e) => e.courseCode).toSet().toList();
    String? selectedCourseCode = uniqueCourseCodes.first;
    ReadyMadeEntry? selectedEntry;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final coursesByCode = entries.where((e) => e.courseCode == selectedCourseCode).toList();
          selectedEntry ??= coursesByCode.first;

          return AlertDialog(
            title: const Text('Import Cloud Template'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCourseCode,
                  decoration: const InputDecoration(labelText: 'Select Course'),
                  items: uniqueCourseCodes.map((c) => DropdownMenuItem(
                    value: c, 
                    child: Text(ReadyMadeService.fileNameMapping[c] ?? c)
                  )).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedCourseCode = val;
                      selectedEntry = entries.firstWhere((e) => e.courseCode == val);
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReadyMadeEntry>(
                  value: selectedEntry,
                  decoration: const InputDecoration(labelText: 'Select Section (Class)'),
                  items: coursesByCode.map((e) => DropdownMenuItem(
                    value: e, 
                    child: Text(e.className)
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedEntry = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedEntry != null) {
                    await _performImport(selectedEntry!);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Import Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performImport(ReadyMadeEntry entry) async {
    final assessments = await _readyMadeService.loadAssessments(entry.courseCode);
    final courseName = ReadyMadeService.fileNameMapping[entry.courseCode] ?? entry.courseCode;

    final newCourse = Course(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: courseName,
      courseCode: entry.courseCode,
      credits: entry.credits,
      colorValue: Colors.primaries[_allCourses.length % Colors.primaries.length].toARGB32(),
      courseworkWeight: entry.courseworkWeight,
      finalWeight: 100 - entry.courseworkWeight,
      semesterId: _activeSemesterId,
      lectureTime: _readyMadeService.convertTimeFormat(entry.lecTime),
      lectureRoom: entry.lecRoom,
      hasLab: entry.labTime.toLowerCase() != 'none',
      labTime: _readyMadeService.convertTimeFormat(entry.labTime),
      labRoom: entry.labRoom,
      assessments: assessments,
    );

    setState(() {
      _allCourses.add(newCourse);
      _applyFilter();
    });
    await StorageService.saveCourses(_allCourses);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $courseName successfully!')));
  }

  void _showCourseDialog({Course? course}) {
    if (course != null) {
      _nameController.text = course.name;
      _codeController.text = course.courseCode ?? '';
      _creditsController.text = course.credits.toString();
      _courseworkWeight = course.courseworkWeight;
      _finalWeight = course.finalWeight;
      _selectedSemesterId = course.semesterId;
      
      _lectureRoomController.text = course.lectureRoom ?? '';
      _lectureSecController.text = course.lectureSection ?? '';
      _lectureDuration = course.lectureDuration;
      _hasTutorial = course.hasTutorial;
      _tutorialRoomController.text = course.tutorialRoom ?? '';
      _tutorialSecController.text = course.tutorialSection ?? '';
      _tutorialDuration = course.tutorialDuration;
      _hasLab = course.hasLab;
      _labRoomController.text = course.labRoom ?? '';
      _labSecController.text = course.labSection ?? '';
      _labDuration = course.labDuration;
      _isPassFail = course.isPassFail;
      _selectedColor = course.colorValue;

      if (course.lectureTime != null && course.lectureTime!.contains(' ')) {
        final parts = course.lectureTime!.split(' ');
        _lectureDay = int.parse(parts[0]);
        final timeParts = parts[1].split(':');
        _lectureTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }
      if (course.tutorialTime != null && course.tutorialTime!.contains(' ')) {
        final parts = course.tutorialTime!.split(' ');
        _tutorialDay = int.parse(parts[0]);
        final timeParts = parts[1].split(':');
        _tutorialTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }
      if (course.labTime != null && course.labTime!.contains(' ')) {
        final parts = course.labTime!.split(' ');
        _labDay = int.parse(parts[0]);
        final timeParts = parts[1].split(':');
        _labTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }
    } else {
      _nameController.clear();
      _codeController.clear();
      _creditsController.clear();
      _courseworkWeight = 60.0;
      _finalWeight = 40.0;
      _selectedSemesterId = _activeSemesterId;
      _lectureRoomController.clear();
      _lectureSecController.clear();
      _lectureDuration = 120;
      _tutorialRoomController.clear();
      _tutorialSecController.clear();
      _tutorialDuration = 120;
      _labRoomController.clear();
      _labSecController.clear();
      _labDuration = 120;
      _hasTutorial = false;
      _hasLab = false;
      _isPassFail = false;
      _selectedColor = Colors.primaries[_allCourses.length % Colors.primaries.length].toARGB32();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(course == null ? 'Add Course' : 'Edit Course', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // CARD 1: Identity
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Color(_selectedColor), width: 2)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Identity', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: _codeController,
                                            decoration: const InputDecoration(labelText: 'Code (e.g. CSC)'),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        GestureDetector(
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (ctx) => Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: Wrap(
                                                  spacing: 12,
                                                  runSpacing: 12,
                                                  children: Colors.primaries.map((color) => GestureDetector(
                                                    onTap: () {
                                                      setDialogState(() => _selectedColor = color.toARGB32());
                                                      Navigator.pop(ctx);
                                                    },
                                                    child: CircleAvatar(backgroundColor: color),
                                                  )).toList(),
                                                ),
                                              )
                                            );
                                          },
                                          child: CircleAvatar(backgroundColor: Color(_selectedColor), child: const Icon(Icons.color_lens, color: Colors.white, size: 20)),
                                        ),
                                      ],
                                    ),
                                    TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(labelText: 'Course Name'),
                                    ),
                                    DropdownButtonFormField<String?>(
                                      value: _selectedSemesterId,
                                      decoration: const InputDecoration(labelText: 'Semester'),
                                      items: [
                                        const DropdownMenuItem<String?>(value: null, child: Text('Undefined')),
                                        ..._semesters.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                                      ],
                                      onChanged: (val) => setDialogState(() => _selectedSemesterId = val),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // CARD 2: Academic
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Academic Rules', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _creditsController,
                                            decoration: const InputDecoration(labelText: 'Credits'),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: CheckboxListTile(
                                            title: const Text('PS Mode', style: TextStyle(fontSize: 14)),
                                            subtitle: const Text('Pass/Fail', style: TextStyle(fontSize: 10)),
                                            value: _isPassFail,
                                            dense: true,
                                            contentPadding: const EdgeInsets.only(left: 8),
                                            onChanged: (val) => setDialogState(() => _isPassFail = val ?? false),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Coursework Weight: ${_courseworkWeight.round()}% | Final: ${_finalWeight.round()}%', style: const TextStyle(fontSize: 12)),
                                    Slider(
                                      value: _courseworkWeight,
                                      min: 0,
                                      max: 100,
                                      divisions: 20,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          _courseworkWeight = value;
                                          _finalWeight = 100 - _courseworkWeight;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // CARD 3: Logistics
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Schedule & Logistics', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 12),
                                    const Text('Lecture', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                                    _buildScheduleRow(
                                      context,
                                      setDialogState,
                                      day: _lectureDay,
                                      time: _lectureTime,
                                      duration: _lectureDuration,
                                      roomController: _lectureRoomController,
                                      secController: _lectureSecController,
                                      onDayChanged: (d) => _lectureDay = d,
                                      onTimeChanged: (t) => _lectureTime = t,
                                      onDurationChanged: (dur) => _lectureDuration = dur,
                                    ),
                                    const Divider(),
                                    CheckboxListTile(
                                      title: const Text('Has Tutorial?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                                      value: _hasTutorial,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (val) => setDialogState(() => _hasTutorial = val ?? false),
                                    ),
                                    if (_hasTutorial)
                                      _buildScheduleRow(
                                        context,
                                        setDialogState,
                                        day: _tutorialDay,
                                        time: _tutorialTime,
                                        duration: _tutorialDuration,
                                        roomController: _tutorialRoomController,
                                        secController: _tutorialSecController,
                                        onDayChanged: (d) => _tutorialDay = d,
                                        onTimeChanged: (t) => _tutorialTime = t,
                                        onDurationChanged: (dur) => _tutorialDuration = dur,
                                      ),
                                    const Divider(),
                                    CheckboxListTile(
                                      title: const Text('Has Lab?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                                      value: _hasLab,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (val) => setDialogState(() => _hasLab = val ?? false),
                                    ),
                                    if (_hasLab)
                                      _buildScheduleRow(
                                        context,
                                        setDialogState,
                                        day: _labDay,
                                        time: _labTime,
                                        duration: _labDuration,
                                        roomController: _labRoomController,
                                        secController: _labSecController,
                                        onDayChanged: (d) => _labDay = d,
                                        onTimeChanged: (t) => _labTime = t,
                                        onDurationChanged: (dur) => _labDuration = dur,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (course == null) {
                                _addCourse();
                              } else {
                                _editCourse(course);
                              }
                            },
                            child: Text(course == null ? 'Add' : 'Save'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScheduleRow(
    BuildContext context,
    StateSetter setDialogState, {
    required int day,
    required TimeOfDay time,
    required int duration,
    required TextEditingController roomController,
    required TextEditingController secController,
    required Function(int) onDayChanged,
    required Function(TimeOfDay) onTimeChanged,
    required Function(int) onDurationChanged,
  }) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: day,
                isExpanded: true,
                items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text(days[i], style: const TextStyle(fontSize: 12)))),
                onChanged: (val) {
                  if (val != null) setDialogState(() => onDayChanged(val));
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: DropdownButton<int>(
                value: time.hour,
                isExpanded: true,
                items: [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19].map((h) {
                  String label = h < 12 ? '$h AM' : (h == 12 ? '12 PM' : '${h - 12} PM');
                  return DropdownMenuItem(value: h, child: Text(label, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => onTimeChanged(TimeOfDay(hour: val, minute: 0)));
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: DropdownButton<int>(
                value: duration,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30m', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 60, child: Text('1h', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 90, child: Text('1.5h', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 120, child: Text('2h', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 180, child: Text('3h', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => onDurationChanged(val));
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: roomController,
                decoration: const InputDecoration(labelText: 'Room', isDense: true),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: secController,
                decoration: const InputDecoration(labelText: 'Sec (e.g. TC1)', isDense: true),
                maxLength: 4,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addCourse() {
    if (_nameController.text.isNotEmpty &&
        _codeController.text.isNotEmpty &&
        _creditsController.text.isNotEmpty) {
      final newCourse = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        courseCode: _codeController.text,
        credits: int.tryParse(_creditsController.text) ?? 3,
        colorValue: _selectedColor,
        isPassFail: _isPassFail,
        courseworkWeight: _courseworkWeight,
        finalWeight: _finalWeight,
        semesterId: _selectedSemesterId,
        lectureTime: '$_lectureDay ${_lectureTime.hour}:${_lectureTime.minute}',
        lectureRoom: _lectureRoomController.text,
        lectureSection: _lectureSecController.text,
        lectureDuration: _lectureDuration,
        hasTutorial: _hasTutorial,
        tutorialTime: _hasTutorial ? '$_tutorialDay ${_tutorialTime.hour}:${_tutorialTime.minute}' : null,
        tutorialRoom: _hasTutorial ? _tutorialRoomController.text : null,
        tutorialSection: _hasTutorial ? _tutorialSecController.text : null,
        tutorialDuration: _tutorialDuration,
        hasLab: _hasLab,
        labTime: _hasLab ? '$_labDay ${_labTime.hour}:${_labTime.minute}' : null,
        labRoom: _hasLab ? _labRoomController.text : null,
        labSection: _hasLab ? _labSecController.text : null,
        labDuration: _labDuration,
      );
      setState(() {
        _allCourses.add(newCourse);
        _applyFilter();
      });
      StorageService.saveCourses(_allCourses);
      Navigator.pop(context);
    }
  }

  void _editCourse(Course course) {
    setState(() {
      course.name = _nameController.text;
      course.courseCode = _codeController.text;
      course.credits = int.tryParse(_creditsController.text) ?? 3;
      course.colorValue = _selectedColor;
      course.isPassFail = _isPassFail;
      course.courseworkWeight = _courseworkWeight;
      course.finalWeight = _finalWeight;
      course.semesterId = _selectedSemesterId;
      course.lectureTime = '$_lectureDay ${_lectureTime.hour}:${_lectureTime.minute}';
      course.lectureRoom = _lectureRoomController.text;
      course.lectureSection = _lectureSecController.text;
      course.lectureDuration = _lectureDuration;
      course.hasTutorial = _hasTutorial;
      course.tutorialTime = _hasTutorial ? '$_tutorialDay ${_tutorialTime.hour}:${_tutorialTime.minute}' : null;
      course.tutorialRoom = _hasTutorial ? _tutorialRoomController.text : null;
      course.tutorialSection = _hasTutorial ? _tutorialSecController.text : null;
      course.tutorialDuration = _tutorialDuration;
      course.hasLab = _hasLab;
      course.labTime = _hasLab ? '$_labDay ${_labTime.hour}:${_labTime.minute}' : null;
      course.labRoom = _hasLab ? _labRoomController.text : null;
      course.labSection = _hasLab ? _labSecController.text : null;
      course.labDuration = _labDuration;
      _applyFilter();
    });
    StorageService.saveCourses(_allCourses);
    Navigator.pop(context);
  }

  void _deleteCourse(Course course) {
    setState(() {
      _allCourses.remove(course);
      _applyFilter();
    });
    StorageService.saveCourses(_allCourses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            const Text('UniTask'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Backup/Restore',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Semester Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SemesterManagementScreen()));
            },
          ),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_allCourses.isEmpty && _filteredCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Start your academic journey!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Add your courses manually or import them directly from the cloud.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'Manual Add',
                      Icons.add_task,
                      Colors.blueAccent,
                      () => _showCourseDialog(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      'Cloud Import',
                      Icons.cloud_download,
                      Colors.cyanAccent,
                      _showImportDialog,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_filteredCourses.isNotEmpty) _buildCloudImportBanner(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 600,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 120,
            ),
            itemCount: _filteredCourses.length,
            itemBuilder: (context, index) {
              final course = _filteredCourses[index];
              return _buildCourseCard(course);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCloudImportBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyanAccent.withValues(alpha: 0.1), Colors.blueAccent.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.cyanAccent),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready-made Courses', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Import all dates and tasks from Cloud', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showImportDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('IMPORT'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: course.color, width: 2),
      ),
      child: Center(
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(
                  course: course,
                  onCourseUpdated: _loadData,
                ),
              ),
            ).then((_) => _loadData());
          },
          leading: CircleAvatar(
            backgroundColor: course.color.withValues(alpha: 0.2),
            child: Text(
              course.credits.toString(),
              style: TextStyle(color: course.color, fontWeight: FontWeight.bold),
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (course.isPassFail)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('PS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
            ],
          ),
          subtitle: Text(course.courseCode ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showCourseDialog(course: course),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteCourse(course),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

