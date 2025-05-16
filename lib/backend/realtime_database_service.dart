import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  static final RealtimeDatabaseService _instance =
      RealtimeDatabaseService._internal();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Singleton pattern
  factory RealtimeDatabaseService() {
    return _instance;
  }

  RealtimeDatabaseService._internal();

  // Get a database reference
  DatabaseReference ref(String path) {
    return _database.ref(path);
  }

  // Set data
  Future<void> setData(String path, Map<String, dynamic> data) async {
    await _database.ref(path).set(data);
  }

  // Update data
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _database.ref(path).update(data);
  }

  // Push data (creates a unique key)
  Future<String> pushData(String path, Map<String, dynamic> data) async {
    final newRef = _database.ref(path).push();
    await newRef.set(data);
    return newRef.key ?? '';
  }

  // Delete data
  Future<void> deleteData(String path) async {
    await _database.ref(path).remove();
  }

  // Listen to data changes (real-time)
  Stream<DatabaseEvent> listenToData(String path) {
    return _database.ref(path).onValue;
  }

  // Listen to child added events
  Stream<DatabaseEvent> listenToChildAdded(String path) {
    return _database.ref(path).onChildAdded;
  }

  // Listen to child changed events
  Stream<DatabaseEvent> listenToChildChanged(String path) {
    return _database.ref(path).onChildChanged;
  }

  // Listen to child removed events
  Stream<DatabaseEvent> listenToChildRemoved(String path) {
    return _database.ref(path).onChildRemoved;
  }

  // Get data once
  Future<DataSnapshot> getData(String path) async {
    return await _database.ref(path).get();
  }
}
