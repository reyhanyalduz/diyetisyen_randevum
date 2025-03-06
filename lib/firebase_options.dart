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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBhHXTGc3E1B4pV96mD1S8GE8ysM_6K2ck',
    appId: '1:381357504974:web:cee441d5435f7f26b3539f',
    messagingSenderId: '381357504974',
    projectId: 'diyetisyenapp4-7485',
    authDomain: 'diyetisyenapp4-7485.firebaseapp.com',
    storageBucket: 'diyetisyenapp4-7485.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCt3hiAfaojIb7Gmk-tPy_K3Uo468K0nDU',
    appId: '1:381357504974:android:11857b6ae2d25764b3539f',
    messagingSenderId: '381357504974',
    projectId: 'diyetisyenapp4-7485',
    storageBucket: 'diyetisyenapp4-7485.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD44_k3RykchBiupFCgmybME7O93Ss-zS0',
    appId: '1:381357504974:ios:5867fb083e767d14b3539f',
    messagingSenderId: '381357504974',
    projectId: 'diyetisyenapp4-7485',
    storageBucket: 'diyetisyenapp4-7485.firebasestorage.app',
    iosBundleId: 'com.example.diyetisyenRandevum',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD44_k3RykchBiupFCgmybME7O93Ss-zS0',
    appId: '1:381357504974:ios:5867fb083e767d14b3539f',
    messagingSenderId: '381357504974',
    projectId: 'diyetisyenapp4-7485',
    storageBucket: 'diyetisyenapp4-7485.firebasestorage.app',
    iosBundleId: 'com.example.diyetisyenRandevum',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBhHXTGc3E1B4pV96mD1S8GE8ysM_6K2ck',
    appId: '1:381357504974:web:d3a726b7b535b01cb3539f',
    messagingSenderId: '381357504974',
    projectId: 'diyetisyenapp4-7485',
    authDomain: 'diyetisyenapp4-7485.firebaseapp.com',
    storageBucket: 'diyetisyenapp4-7485.firebasestorage.app',
  );

}