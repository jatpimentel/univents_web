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
    apiKey: 'AIzaSyDQFPFLuYvCT7XA1PIlObTuSGooJRZt3dQ',
    appId: '1:1078014833550:web:0d0e7e61cb8e9581b6aadf',
    messagingSenderId: '1078014833550',
    projectId: 'it5-teamd2',
    authDomain: 'it5-teamd2.firebaseapp.com',
    storageBucket: 'it5-teamd2.firebasestorage.app',
    measurementId: 'G-R4JXF59L84',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtxYce_4Mnq_7wjMGWdxlWsI7KchSlJVw',
    appId: '1:1078014833550:android:e05df7ab264e4f69b6aadf',
    messagingSenderId: '1078014833550',
    projectId: 'it5-teamd2',
    storageBucket: 'it5-teamd2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBUW1eZlVWdHZVNPet2p28_rC441A1GTh4',
    appId: '1:1078014833550:ios:97c747b605daee9db6aadf',
    messagingSenderId: '1078014833550',
    projectId: 'it5-teamd2',
    storageBucket: 'it5-teamd2.firebasestorage.app',
    androidClientId: '1078014833550-vi11u9u41bvm5gpmr4s47du7snk7eqbg.apps.googleusercontent.com',
    iosClientId: '1078014833550-97obn6vunvmvq5c0pdcc7biq08rn4cbn.apps.googleusercontent.com',
    iosBundleId: 'com.example.univentsWeb',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBUW1eZlVWdHZVNPet2p28_rC441A1GTh4',
    appId: '1:1078014833550:ios:97c747b605daee9db6aadf',
    messagingSenderId: '1078014833550',
    projectId: 'it5-teamd2',
    storageBucket: 'it5-teamd2.firebasestorage.app',
    androidClientId: '1078014833550-vi11u9u41bvm5gpmr4s47du7snk7eqbg.apps.googleusercontent.com',
    iosClientId: '1078014833550-97obn6vunvmvq5c0pdcc7biq08rn4cbn.apps.googleusercontent.com',
    iosBundleId: 'com.example.univentsWeb',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDQFPFLuYvCT7XA1PIlObTuSGooJRZt3dQ',
    appId: '1:1078014833550:web:8e859fe5218633b1b6aadf',
    messagingSenderId: '1078014833550',
    projectId: 'it5-teamd2',
    authDomain: 'it5-teamd2.firebaseapp.com',
    storageBucket: 'it5-teamd2.firebasestorage.app',
    measurementId: 'G-KDM1M6VL9Q',
  );
}
