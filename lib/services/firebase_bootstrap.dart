import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Trang thai Firebase: false khi chua dat google-services.json —
/// app van chay che do local (admin demo), login email se bao loi ro rang.
bool firebaseReady = false;

Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    firebaseReady = false;
    debugPrint('Firebase chua cau hinh (thieu google-services.json?): $e');
  }
}
