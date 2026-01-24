import 'package:flutter/material.dart';
import 'course_model.dart';
import 'storage_service.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];

  // Controllers and State Variables
  final _nameController = TextEditingController();
  final _profController = TextEditingController();
  final _creditsController = TextEditingController();
  double _courseworkWeight = 60.0;
  double _finalWeight = 40.0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final courses = await StorageService.loadCourses();
    setState(() {
      _courses = courses;
    });
  }

  void _showCourseDialog({Course? course}) {
    if (course != null) {
      _nameController.text = course.name;
      _profController.text = course.professor;
      _creditsController.text = course.credits.toString();
      _courseworkWeight = course.courseworkWeight;
      _finalWeight = course.finalWeight;
    } else {
      _nameController.clear();
      _profController.clear();
      _creditsController.clear();
      _courseworkWeight = 60.0;
      _finalWeight = 40.0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(course == null ? 'Add Course' : 'Edit Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Course Name',
                      ),
                    ),
                    TextField(
                      controller: _profController,
                      decoration: const InputDecoration(
                        labelText: 'Professor Name',
                      ),
                    ),
                    TextField(
                      controller: _creditsController,
                      decoration: const InputDecoration(labelText: 'Credits'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text('Coursework Weight: ${_courseworkWeight.round()}%'),
                    Slider(
                      value: _courseworkWeight,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _courseworkWeight.round().toString(),
                      onChanged: (value) {
                        setDialogState(() {
                          _courseworkWeight = value;
                          _finalWeight = 100 - _courseworkWeight;
                        });
                      },
                    ),
                    Text('Final Weight: ${_finalWeight.round()}%'),
                    Slider(
                      value: _finalWeight,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _finalWeight.round().toString(),
                      onChanged: (value) {
                        setDialogState(() {
                          _finalWeight = value;
                          _courseworkWeight = 100 - _finalWeight;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
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
            );
          },
        );
      },
    );
  }

  void _addCourse() {
    if (_nameController.text.isNotEmpty &&
        _profController.text.isNotEmpty &&
        _creditsController.text.isNotEmpty &&
        int.tryParse(_creditsController.text) != null) {
      setState(() {
        _courses.add(
          Course(
            id: DateTime.now().toString(),
            name: _nameController.text,
            professor: _profController.text,
            credits: int.parse(_creditsController.text),
            colorValue: Colors
                .primaries[_courses.length % Colors.primaries.length]
                .toARGB32(),
            courseworkWeight: _courseworkWeight,
            finalWeight: _finalWeight,
          ),
        );
      });
      StorageService.saveCourses(_courses);
      Navigator.pop(context);
    }
  }

  void _editCourse(Course course) {
    if (_nameController.text.isNotEmpty &&
        _profController.text.isNotEmpty &&
        _creditsController.text.isNotEmpty &&
        int.tryParse(_creditsController.text) != null) {
      setState(() {
        course.name = _nameController.text;
        course.professor = _profController.text;
        course.credits = int.parse(_creditsController.text);
        course.courseworkWeight = _courseworkWeight;
        course.finalWeight = _finalWeight;
      });
      StorageService.saveCourses(_courses);
      Navigator.pop(context);
    }
  }

  void _deleteCourse(Course course) {
    setState(() {
      _courses.remove(course);
    });
    StorageService.saveCourses(_courses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: _courses.isEmpty
          ? const Center(child: Text('No courses added yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 600,
                childAspectRatio: 3, // Adjust based on card content
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 120, // Fixed height for cards
              ),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
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
                              onCourseUpdated: _loadCourses,
                            ),
                          ),
                        ).then((_) => _loadCourses());
                      },
                      leading: CircleAvatar(
                        backgroundColor: course.color.withValues(alpha: 0.2),
                        child: Text(
                          course.credits.toString(),
                          style: TextStyle(
                            color: course.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        course.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Prof. ${course.professor}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showCourseDialog(course: course),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteCourse(course),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
