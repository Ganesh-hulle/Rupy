import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Centralized configuration for the named Firestore database.
class RupyFirestore {
  /// Returns the Firestore instance for the 'rupy' database.
  static FirebaseFirestore get instance {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'rupy',
    );
  }
}
