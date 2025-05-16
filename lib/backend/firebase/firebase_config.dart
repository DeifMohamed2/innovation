import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCIdw9z_30sVfeHrpNqFwrLCMKWmgqD5X8",
            authDomain: "smarthub-60812.firebaseapp.com",
            projectId: "smarthub-60812",
            storageBucket: "smarthub-60812.firebasestorage.app",
            messagingSenderId: "76707154475",
            appId: "1:76707154475:web:1c6b6c91392f67303f386e",
            measurementId: "G-2MH4HCND20",
            databaseURL: "https://smarthub-60812-default-rtdb.firebaseio.com"));
  } else {
    await Firebase.initializeApp();
  }
}
