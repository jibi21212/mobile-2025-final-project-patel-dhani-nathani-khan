import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase not configured for web. Run flutterfire configure and select web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase not configured for iOS. Add GoogleService-Info.plist and rerun flutterfire configure.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Firebase not configured for macOS. Rerun flutterfire configure with macOS selected.',
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase not configured for ${defaultTargetPlatform.name}. Rerun flutterfire configure for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCEqAewbI7hXbenVPGV3dNtQvIcLOmO_VE',
    appId: '1:557085702762:android:b51da825188e6eef83a813',
    messagingSenderId: '557085702762',
    projectId: 'mobile-final-75cbf',
    storageBucket: 'mobile-final-75cbf.firebasestorage.app',
  );
}
