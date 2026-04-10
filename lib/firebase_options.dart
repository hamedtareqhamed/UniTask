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

  static String _get(String envVal, String key, {String fallback = ''}) {
    return envVal.isNotEmpty ? envVal : dotenv.get(key, fallback: fallback);
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _get(const String.fromEnvironment('FLUTTER_FIREBASE_API_KEY_WEB'), 'FLUTTER_FIREBASE_API_KEY_WEB'),
    appId: _get(const String.fromEnvironment('FLUTTER_FIREBASE_APP_ID_WEB'), 'FLUTTER_FIREBASE_APP_ID_WEB'),
    messagingSenderId: _get(const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'), 'FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _get(const String.fromEnvironment('FIREBASE_PROJECT_ID'), 'FIREBASE_PROJECT_ID'),
    authDomain: _get(const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'), 'FIREBASE_AUTH_DOMAIN'),
    storageBucket: _get(const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'), 'FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _get(const String.fromEnvironment('FLUTTER_FIREBASE_API_KEY_ANDROID'), 'FLUTTER_FIREBASE_API_KEY_ANDROID'),
    appId: _get(const String.fromEnvironment('FLUTTER_FIREBASE_APP_ID_ANDROID'), 'FLUTTER_FIREBASE_APP_ID_ANDROID'),
    messagingSenderId: _get(const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'), 'FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _get(const String.fromEnvironment('FIREBASE_PROJECT_ID'), 'FIREBASE_PROJECT_ID'),
    storageBucket: _get(const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'), 'FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _get(const String.fromEnvironment('FLUTTER_FIREBASE_API_KEY_IOS'), 'FLUTTER_FIREBASE_API_KEY_IOS'),
    appId: _get(const String.fromEnvironment('FLUTTER_FIREBASE_APP_ID_IOS'), 'FLUTTER_FIREBASE_APP_ID_IOS'),
    messagingSenderId: _get(const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'), 'FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _get(const String.fromEnvironment('FIREBASE_PROJECT_ID'), 'FIREBASE_PROJECT_ID'),
    storageBucket: _get(const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'), 'FIREBASE_STORAGE_BUCKET'),
    iosBundleId: 'dev.albazeli.unitask',
  );
}
