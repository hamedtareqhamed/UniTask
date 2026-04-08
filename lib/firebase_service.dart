import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_service.dart';
import 'course_model.dart';
import 'task_model.dart';
import 'note_model.dart';
import 'semester_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1045468371720-klnj4p0dp6u7ipsrk8nn6flmei7477mt.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> uploadBackup() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final tasks = await StorageService.loadTasks();
    final courses = await StorageService.loadCourses();
    final notes = await StorageService.loadNotes();
    final semesters = await StorageService.loadSemesters();
    final activeSemesterId = await StorageService.loadActiveSemesterId();

    final backupData = {
      'lastBackup': FieldValue.serverTimestamp(),
      'activeSemesterId': activeSemesterId,
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'courses': courses.map((c) => c.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'semesters': semesters.map((s) => s.toMap()).toList(),
    };

    await _db.collection('backups').doc(user.uid).set(backupData);
  }

  Future<void> downloadRestore() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final doc = await _db.collection('backups').doc(user.uid).get();
    if (!doc.exists) throw Exception('No backup found');

    final data = doc.data()!;

    // Restore active semester
    await StorageService.saveActiveSemesterId(data['activeSemesterId']);

    // Restore tasks
    final tasksData = (data['tasks'] as List<dynamic>? ?? []);
    final tasks = tasksData.map((t) => Task.fromMap(t as Map<String, dynamic>)).toList();
    await StorageService.saveTasks(tasks);

    // Restore courses
    final coursesData = (data['courses'] as List<dynamic>? ?? []);
    final courses = coursesData.map((c) => Course.fromMap(c as Map<String, dynamic>)).toList();
    await StorageService.saveCourses(courses);

    // Restore notes
    final notesData = (data['notes'] as List<dynamic>? ?? []);
    final notes = notesData.map((n) => Note.fromMap(n as Map<String, dynamic>)).toList();
    await StorageService.saveNotes(notes);

    // Restore semesters
    final semestersData = (data['semesters'] as List<dynamic>? ?? []);
    final semesters = semestersData.map((s) => Semester.fromMap(s as Map<String, dynamic>)).toList();
    await StorageService.saveSemesters(semesters);
  }
}
