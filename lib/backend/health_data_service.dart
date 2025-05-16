import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'realtime_database_service.dart';

class HealthDataService {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Base path for health data
  String get _basePath =>
      'health_data/${_auth.currentUser?.uid ?? 'anonymous'}';

  // Heart rate data path
  String get _heartRatePath => '$_basePath/heart_rate';

  // Temperature data path
  String get _temperaturePath => '$_basePath/temperature';

  // Add a heart rate reading
  Future<void> addHeartRateReading(int bpm) async {
    final data = {
      'bpm': bpm,
      'timestamp': ServerValue.timestamp,
    };
    await _dbService.pushData(_heartRatePath, data);
  }

  // Add a temperature reading
  Future<void> addTemperatureReading(double temperature) async {
    final data = {
      'temperature': temperature,
      'timestamp': ServerValue.timestamp,
    };
    await _dbService.pushData(_temperaturePath, data);
  }

  // Get latest heart rate reading
  Future<Map<String, dynamic>?> getLatestHeartRate() async {
    final snapshot = await _dbService
        .ref(_heartRatePath)
        .orderByChild('timestamp')
        .limitToLast(1)
        .get();

    if (snapshot.value == null) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final entry = data.entries.first;
    final reading = Map<String, dynamic>.from(entry.value as Map);
    reading['id'] = entry.key;

    return reading;
  }

  // Get latest temperature reading
  Future<Map<String, dynamic>?> getLatestTemperature() async {
    final snapshot = await _dbService
        .ref(_temperaturePath)
        .orderByChild('timestamp')
        .limitToLast(1)
        .get();

    if (snapshot.value == null) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final entry = data.entries.first;
    final reading = Map<String, dynamic>.from(entry.value as Map);
    reading['id'] = entry.key;

    return reading;
  }

  // Stream of heart rate readings
  Stream<DatabaseEvent> streamHeartRateReadings() {
    return _dbService
        .ref(_heartRatePath)
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue;
  }

  // Stream of temperature readings
  Stream<DatabaseEvent> streamTemperatureReadings() {
    return _dbService
        .ref(_temperaturePath)
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue;
  }

  // Update user health profile
  Future<void> updateHealthProfile(Map<String, dynamic> profileData) async {
    await _dbService.updateData('$_basePath/profile', profileData);
  }

  // Get user health profile
  Future<Map<String, dynamic>?> getHealthProfile() async {
    final snapshot = await _dbService.getData('$_basePath/profile');
    if (snapshot.value == null) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  // Stream user health profile
  Stream<DatabaseEvent> streamHealthProfile() {
    return _dbService.listenToData('$_basePath/profile');
  }
}
