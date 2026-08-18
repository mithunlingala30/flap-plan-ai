import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// PLACEHOLDER FILE — auto-generate the real one with the FlutterFire CLI.
///
/// This file is normally generated for you, not written by hand. Once you
/// have this project open locally with the Flutter SDK installed, run:
///
///   dart pub global activate flutterfire_cli
///   flutterfire configure
///
/// ...and select (or create) your Firebase project. That command will
/// OVERWRITE this file with real apiKey/appId/projectId values for each
/// platform (Android, iOS, Web, etc.) and also drop the matching native
/// config files (google-services.json, GoogleService-Info.plist) into your
/// android/ and ios/ folders automatically.
///
/// The placeholder values below will NOT work — the app will throw a
/// Firebase initialization error until you run flutterfire configure.
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run `flutterfire configure` to add it.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDR7prwxXQhr7oOgX-8luan5mzDZHk3Erk',
    appId: '1:483329516369:web:6843d3d1417b9629c1e970',
    messagingSenderId: '483329516369',
    projectId: 'flap-plan-587ec',
    authDomain: 'flap-plan-587ec.firebaseapp.com',
    databaseURL: 'https://flap-plan-587ec-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'flap-plan-587ec.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3qIkijA8Uh-5FdcpL_sp4AuUi39ThFuY',
    appId: '1:483329516369:android:0d609d51c812c519c1e970',
    messagingSenderId: '483329516369',
    projectId: 'flap-plan-587ec',
    databaseURL: 'https://flap-plan-587ec-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'flap-plan-587ec.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAoGE4nsK8q70r2QgjW4cYJkq5p9L8cDQI',
    appId: '1:483329516369:ios:78cb5ff05880f9a0c1e970',
    messagingSenderId: '483329516369',
    projectId: 'flap-plan-587ec',
    databaseURL: 'https://flap-plan-587ec-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'flap-plan-587ec.firebasestorage.app',
    iosClientId: '483329516369-k2ufu96ids1ijodai5o3aaq5hsqlpurf.apps.googleusercontent.com',
    iosBundleId: 'com.example.app',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAoGE4nsK8q70r2QgjW4cYJkq5p9L8cDQI',
    appId: '1:483329516369:ios:78cb5ff05880f9a0c1e970',
    messagingSenderId: '483329516369',
    projectId: 'flap-plan-587ec',
    databaseURL: 'https://flap-plan-587ec-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'flap-plan-587ec.firebasestorage.app',
    iosClientId: '483329516369-k2ufu96ids1ijodai5o3aaq5hsqlpurf.apps.googleusercontent.com',
    iosBundleId: 'com.example.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDR7prwxXQhr7oOgX-8luan5mzDZHk3Erk',
    appId: '1:483329516369:web:034cfc444d48ce9bc1e970',
    messagingSenderId: '483329516369',
    projectId: 'flap-plan-587ec',
    authDomain: 'flap-plan-587ec.firebaseapp.com',
    databaseURL: 'https://flap-plan-587ec-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'flap-plan-587ec.firebasestorage.app',
  );
}
