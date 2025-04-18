// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCD29OUu4SiGF1nJr-1Bs-xoZlgWYPNWFw',
    appId: '1:557447830332:web:0530b58f7359007b2c9c39',
    messagingSenderId: '557447830332',
    projectId: 'focus-5-app',
    authDomain: 'focus-5-app.firebaseapp.com',
    storageBucket: 'focus-5-app.firebasestorage.app',
    measurementId: 'G-KG427GW2H7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWK3eFOZHOAEtMziYINApteZ1BiG87BFk',
    appId: '1:557447830332:android:5ede81ffc6863ec12c9c39',
    messagingSenderId: '557447830332',
    projectId: 'focus-5-app',
    storageBucket: 'focus-5-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDCkmB-IbV6P8uXG6q9Iw0y_MAEL3rZVB0',
    appId: '1:557447830332:ios:b695ed0b6f5affa02c9c39',
    messagingSenderId: '557447830332',
    projectId: 'focus-5-app',
    storageBucket: 'focus-5-app.firebasestorage.app',
    iosBundleId: 'com.example.focus5',
  );
}
