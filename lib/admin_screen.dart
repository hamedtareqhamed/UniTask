import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  String _status = '';

  Future<void> _handleImport() async {
    if (_jsonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste some JSON first!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Parsing & Uploading...';
    });

    try {
      final results = await _adminService.bulkImport(_jsonController.text);
      setState(() {
        _status = 'Success!\n'
            '• Courses: ${results['courses']}\n'
            '• Sections: ${results['sections']}\n'
            '• Assessments: ${results['assessments']}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadSample() {
    final sample = {
      "courses": [
        {
          "code": "TSE",
          "name": "SOFTWARE ENGINEERING",
          "professor": "Dr. Sarah",
          "credits": 3,
          "courseworkWeight": 60,
          "assessments": [
            {"title": "Quiz 1", "type": "quiz", "category": "coursework", "maxScore": 10, "weight": 5, "deadline": "2024-05-01", "isCompleted": false}
          ]
        }
      ],
      "sections": [
        {
          "className": "DS1D",
          "courseCode": "TSE",
          "lecTime": "Monday 2:00PM",
          "labTime": "Tuesday 12:00PM",
          "lecRoom": "CLC L",
          "labRoom": "FOB",
          "instructor": "Dr. Sarah",
          "credits": 3,
          "courseworkWeight": 60.0
        }
      ]
    };
    _jsonController.text = const JsonEncoder.withIndent('  ').convert(sample);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Cloud Manager'),
        actions: [
          IconButton(
            onPressed: () {
              Clipboard.getData(Clipboard.kTextPlain).then((value) {
                if (value?.text != null) {
                  _jsonController.text = value!.text!;
                }
              });
            },
            icon: const Icon(Icons.paste),
            tooltip: 'Paste from Clipboard',
          ),
          IconButton(
            onPressed: _loadSample,
            icon: const Icon(Icons.description),
            tooltip: 'Load Sample JSON',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _jsonController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.cyanAccent,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText: 'Paste FireCMS or Bulk JSON here...',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('Error') 
                      ? Colors.redAccent.withOpacity(0.1) 
                      : Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status.contains('Error') 
                        ? Colors.redAccent.withOpacity(0.3) 
                        : Colors.greenAccent.withOpacity(0.3)
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('Error') ? Colors.redAccent : Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'BULK UPLOAD TO CLOUD',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
