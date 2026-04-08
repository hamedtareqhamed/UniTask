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

    // 1. Load local data
    final localSemesters = await StorageService.loadSemesters();
    final localCourses = await StorageService.loadCourses();
    final localTasks = await StorageService.loadTasks();
    final localNotes = await StorageService.loadNotes();

    // 2. Parse downloaded data
    final cloudSemesters = (data['semesters'] as List<dynamic>? ?? [])
        .map((s) => Semester.fromMap(s as Map<String, dynamic>))
        .toList();
    final cloudCourses = (data['courses'] as List<dynamic>? ?? [])
        .map((c) => Course.fromMap(c as Map<String, dynamic>))
        .toList();
    final cloudTasks = (data['tasks'] as List<dynamic>? ?? [])
        .map((t) => Task.fromMap(t as Map<String, dynamic>))
        .toList();
    final cloudNotes = (data['notes'] as List<dynamic>? ?? [])
        .map((n) => Note.fromMap(n as Map<String, dynamic>))
        .toList();

    Map<String, String> semesterIdMap = {};
    List<Semester> mergedSemesters = List.from(localSemesters);

    // 3. Merge Semesters
    for (var cloudSem in cloudSemesters) {
      int matchIndex = localSemesters.indexWhere((ls) => ls.name == cloudSem.name);
      if (matchIndex != -1) {
        int counter = 1;
        String newName = '${cloudSem.name} $counter';
        while (localSemesters.any((ls) => ls.name == newName)) {
          counter++;
          newName = '${cloudSem.name} $counter';
        }
        cloudSem.name = newName;
        String oldId = cloudSem.id;
        cloudSem.id = DateTime.now().millisecondsSinceEpoch.toString() + 'sem';
        semesterIdMap[oldId] = cloudSem.id;
        mergedSemesters.add(cloudSem);
      } else {
        if (localSemesters.any((ls) => ls.id == cloudSem.id)) {
          String oldId = cloudSem.id;
          cloudSem.id = DateTime.now().millisecondsSinceEpoch.toString() + 'sem${cloudSem.name}';
          semesterIdMap[oldId] = cloudSem.id;
        }
        mergedSemesters.add(cloudSem);
      }
    }

    // 4. Merge Courses
    List<Course> mergedCourses = List.from(localCourses);
    for (var cloudCourse in cloudCourses) {
      if (cloudCourse.semesterId != null && semesterIdMap.containsKey(cloudCourse.semesterId)) {
        cloudCourse.semesterId = semesterIdMap[cloudCourse.semesterId];
      }

      if (cloudCourse.semesterId == null || cloudCourse.semesterId!.isEmpty || cloudCourse.semesterId == 'undefined') {
        cloudCourse.semesterId = null;
        int existingIndex = mergedCourses.indexWhere((lc) => lc.id == cloudCourse.id);
        if (existingIndex != -1) {
          mergedCourses[existingIndex] = cloudCourse;
        } else {
          mergedCourses.add(cloudCourse);
        }
      } else {
        int existingIndex = mergedCourses.indexWhere((lc) => lc.id == cloudCourse.id);
        if (existingIndex != -1) {
          if (mergedCourses[existingIndex].semesterId != cloudCourse.semesterId) {
             cloudCourse.id = DateTime.now().millisecondsSinceEpoch.toString() + 'crs';
             mergedCourses.add(cloudCourse);
          } else {
             mergedCourses[existingIndex] = cloudCourse; // Overwrite if same semester and same ID
          }
        } else {
          mergedCourses.add(cloudCourse);
        }
      }
    }

    // 5. Merge Tasks
    List<Task> mergedTasks = List.from(localTasks);
    for (var cloudTask in cloudTasks) {
      if (cloudTask.semesterId != null && semesterIdMap.containsKey(cloudTask.semesterId)) {
        cloudTask.semesterId = semesterIdMap[cloudTask.semesterId];
      }
      mergedTasks.add(cloudTask);
    }

    // 6. Merge Notes
    List<Note> mergedNotes = List.from(localNotes);
    for (var cloudNote in cloudNotes) {
      int existingIdx = mergedNotes.indexWhere((n) => n.id == cloudNote.id);
      if (existingIdx != -1) {
         mergedNotes[existingIdx] = cloudNote;
      } else {
         mergedNotes.add(cloudNote);
      }
    }

    // 7. Save merged data
    await StorageService.saveSemesters(mergedSemesters);
    await StorageService.saveCourses(mergedCourses);
    await StorageService.saveTasks(mergedTasks);
    await StorageService.saveNotes(mergedNotes);

    if (data['activeSemesterId'] != null) {
      String newActiveId = semesterIdMap[data['activeSemesterId']] ?? data['activeSemesterId'];
      await StorageService.saveActiveSemesterId(newActiveId);
    }
  }
}
