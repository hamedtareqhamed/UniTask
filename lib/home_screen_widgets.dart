import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'gpa_utils.dart';

/// This file contains the UI definitions for iPhone/Android Home Screen Widgets.
/// These can be used with the `home_widget` package to render native widgets.

class WidgetTheme {
  static const backgroundColor = Color(0xFF121212);
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const accentColor = Colors.cyanAccent;
}

class NextClassWidgetUI extends StatelessWidget {
  final String courseName;
  final String type;
  final String time;
  final String? room;

  const NextClassWidgetUI({
    super.key,
    required this.courseName,
    required this.type,
    required this.time,
    this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: WidgetTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NEXT CLASS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          Text(courseName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 12),
              const SizedBox(width: 4),
              Text(time, style: const TextStyle(color: Colors.white, fontSize: 12)),
              const Spacer(),
              if (room != null) ...[
                const Icon(Icons.room, color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(room!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AcademicStandingWidgetUI extends StatelessWidget {
  final double currentGPA;
  final double maxGPA;

  const AcademicStandingWidgetUI({
    super.key,
    required this.currentGPA,
    required this.maxGPA,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WidgetTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WidgetTheme.accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GPA STANDING', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currentGPA.toStringAsFixed(2), style: const TextStyle(color: WidgetTheme.accentColor, fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MAX', style: TextStyle(color: Colors.grey, fontSize: 8)),
                  Text(maxGPA.toStringAsFixed(2), style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              widthFactor: (currentGPA / 4.0).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(decoration: BoxDecoration(color: WidgetTheme.accentColor, borderRadius: BorderRadius.circular(2))),
            ),
          ),
        ],
      ),
    );
  }
}

class ClockWidgetUI extends StatelessWidget {
  const ClockWidgetUI({super.key});

  @override
  Widget build(BuildContext context) {
    final now = GPAUtils.getMalaysiaTime();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(DateFormat('EEEE').format(now).toUpperCase(), style: const TextStyle(color: WidgetTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(DateFormat('hh:mm').format(now), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          Text(DateFormat('MMM d, yyyy').format(now), style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
