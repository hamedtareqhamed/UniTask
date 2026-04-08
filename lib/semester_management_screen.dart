import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'semester_model.dart';
import 'storage_service.dart';

class SemesterManagementScreen extends StatefulWidget {
  const SemesterManagementScreen({super.key});

  @override
  State<SemesterManagementScreen> createState() => _SemesterManagementScreenState();
}

class _SemesterManagementScreenState extends State<SemesterManagementScreen> {
  List<Semester> _semesters = [];
  String? _activeSemesterId;

  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final semesters = await StorageService.loadSemesters();
    final activeId = await StorageService.loadActiveSemesterId();
    setState(() {
      _semesters = semesters;
      _activeSemesterId = activeId;
    });
  }

  void _showAddSemesterDialog({Semester? semester}) {
    if (semester != null) {
      _nameController.text = semester.name;
      _startDate = semester.startDate;
      _endDate = semester.endDate;
    } else {
      _nameController.clear();
      _startDate = null;
      _endDate = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(semester == null ? 'Add Semester' : 'Edit Semester'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Semester Name'),
                  ),
                  ListTile(
                    title: Text(_startDate == null
                        ? 'Select Start Date'
                        : 'Start: ${DateFormat('yyyy-MM-dd').format(_startDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => _startDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: Text(_endDate == null
                        ? 'Select End Date'
                        : 'End: ${DateFormat('yyyy-MM-dd').format(_endDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );

                      if (picked != null) {
                        setDialogState(() => _endDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty &&
                        _startDate != null &&
                        _endDate != null) {
                      if (semester == null) {
                        _addSemester();
                      } else {
                        _editSemester(semester);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(semester == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addSemester() {
    final newSemester = Semester(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      startDate: _startDate!,
      endDate: _endDate!,
    );
    setState(() {
      _semesters.add(newSemester);
    });
    StorageService.saveSemesters(_semesters);
  }

  void _editSemester(Semester semester) {
    setState(() {
      semester.name = _nameController.text;
      semester.startDate = _startDate!;
      semester.endDate = _endDate!;
    });
    StorageService.saveSemesters(_semesters);
  }

  void _deleteSemester(Semester semester) {
    setState(() {
      _semesters.remove(semester);
      if (_activeSemesterId == semester.id) {
        _activeSemesterId = null;
        StorageService.saveActiveSemesterId(null);
      }
    });
    StorageService.saveSemesters(_semesters);
  }

  void _setActiveSemester(String? id) {
    setState(() {
      _activeSemesterId = id;
    });
    StorageService.saveActiveSemesterId(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semesters')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: _activeSemesterId == null
                ? Colors.deepPurpleAccent.withValues(alpha: 0.3)
                : null,
            child: ListTile(
              title: const Text('Undefined (Default)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Subjects not assigned to any semester'),
              trailing: _activeSemesterId == null ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () => _setActiveSemester(null),
            ),
          ),
          const Divider(),
          ..._semesters.map((s) {
            final isActive = _activeSemesterId == s.id;
            return Card(
              color: isActive ? Colors.deepPurpleAccent.withValues(alpha: 0.3) : null,
              child: ListTile(
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${DateFormat('MMM d').format(s.startDate)} - ${DateFormat('MMM d, yyyy').format(s.endDate)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) const Icon(Icons.check_circle, color: Colors.green),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showAddSemesterDialog(semester: s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                      onPressed: () => _deleteSemester(s),
                    ),
                  ],
                ),
                onTap: () => _setActiveSemester(s.id),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSemesterDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
