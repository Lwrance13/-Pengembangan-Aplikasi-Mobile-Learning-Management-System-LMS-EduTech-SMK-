// File ini di-generate berdasarkan konfigurasi Firebase project.
// Project: project-1-96fa1
// Untuk menghubungkan ke Firebase, pastikan:
// 1. Firebase Authentication sudah diaktifkan (Email/Password)
// 2. Cloud Firestore sudah dibuat
// 3. Firebase Storage sudah diaktifkan
// 4. Firebase Hosting sudah diaktifkan

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyAdq20qaUKq_k6ayTO_CZfMs-7aUh_MQs0',
    appId: '1:308032242247:web:a8a2f4a4c9ffbfc5c0e762',
    messagingSenderId: '308032242247',
    projectId: 'project-1-96fa1',
    authDomain: 'project-1-96fa1.firebaseapp.com',
    storageBucket: 'project-1-96fa1.firebasestorage.app',
    measurementId: 'G-X0G4X9SZET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8Iz1m3D-k3Cst2VMxuxNxnkZ_XFwGuHU',
    appId: '1:308032242247:android:56508cd9d64faf3fc0e762',
    messagingSenderId: '308032242247',
    projectId: 'project-1-96fa1',
    storageBucket: 'project-1-96fa1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_fk7Ftd0lIhTiKnGFyF7p3GvujVCAyFo',
    appId: '1:308032242247:ios:bb930489ed55e6e8c0e762',
    messagingSenderId: '308032242247',
    projectId: 'project-1-96fa1',
    storageBucket: 'project-1-96fa1.firebasestorage.app',
    iosClientId: '308032242247-8jg11h7i1l9s9ra2taboabltsphbeqcr.apps.googleusercontent.com',
    iosBundleId: 'com.example.schoolManagement',
  );
}
