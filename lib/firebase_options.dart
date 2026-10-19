import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Firebase configuration options for ChapterOne.
///
/// From google-services.json (project: sdn-ass-a6651)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCBAja-RFydbU3jieNlxQukAoP-1-khw84',
    appId: '1:319281485286:android:df81638c3c2d67f322f227',
    messagingSenderId: '319281485286',
    projectId: 'sdn-ass-a6651',
    storageBucket: 'sdn-ass-a6651.firebasestorage.app',
  );

  // iOS uses the same project — update appId when you register an iOS app
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCBAja-RFydbU3jieNlxQukAoP-1-khw84',
    appId: '1:319281485286:ios:df81638c3c2d67f322f227',
    messagingSenderId: '319281485286',
    projectId: 'sdn-ass-a6651',
    storageBucket: 'sdn-ass-a6651.firebasestorage.app',
    iosBundleId: 'com.chapterone.chapteroneMobile',
  );
}
