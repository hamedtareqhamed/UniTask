import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return android; 
    }
  }

  // Helper to read from Environment (Build-time) or Dotenv (Runtime)
  static String _get(String key, {String fallback = ''}) {
    return String.fromEnvironment(key, defaultValue: dotenv.get(key, fallback: fallback));
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _get('FLUTTER_FIREBASE_API_KEY_WEB'),
    appId: _get('FLUTTER_FIREBASE_APP_ID_WEB'),
    messagingSenderId: _get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _get('FIREBASE_PROJECT_ID'),
    authDomain: _get('FIREBASE_AUTH_DOMAIN'),
    storageBucket: _get('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _get('FLUTTER_FIREBASE_API_KEY_ANDROID'),
    appId: _get('FLUTTER_FIREBASE_APP_ID_ANDROID'),
    messagingSenderId: _get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _get('FIREBASE_PROJECT_ID'),
    storageBucket: _get('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _get('FLUTTER_FIREBASE_API_KEY_IOS'),
    appId: _get('FLUTTER_FIREBASE_APP_ID_IOS'),
    messagingSenderId: _get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _get('FIREBASE_PROJECT_ID'),
    storageBucket: _get('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: 'online.albazly.unitask',
  );
}
