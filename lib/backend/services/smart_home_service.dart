import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/room.dart';
import '../realtime_database_service.dart';
import '../../auth/firebase_auth/auth_util.dart';

class SmartHomeService {
  static final SmartHomeService _instance = SmartHomeService._internal();
  final RealtimeDatabaseService _realtimeDB = RealtimeDatabaseService();

  // Singleton pattern
  factory SmartHomeService() {
    return _instance;
  }

  SmartHomeService._internal();

  // Constants for Firebase paths
  static const String _roomsPath = 'rooms';
  static const String _espControlPath = 'esp_control';

  // Get rooms for current user
  Stream<List<Room>> getRoomsForUser() {
    final currentUser = currentUserReference;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final userId = currentUserUid;

    return _realtimeDB.listenToData(_roomsPath).map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return <Room>[];
      }

      List<Room> rooms = [];
      data.forEach((key, value) {
        if (value is Map && value['userId'] == userId) {
          rooms.add(Room.fromMap(Map<String, dynamic>.from(value), key));
        }
      });

      return rooms;
    });
  }

  // Add a new room
  Future<String> addRoom(String name, String icon, {
    bool hasLights = true,
    bool hasDoor = true,
    int lightPin = 0,
    int doorPin = 0,
  }) async {
    final userId = currentUserUid;

    final room = Room(
      id: '',
      name: name,
      icon: icon,
      userId: userId,
      hasLights: hasLights,
      hasDoor: hasDoor,
      lightPin: lightPin,
      doorPin: doorPin,
    );

    return await _realtimeDB.pushData(_roomsPath, room.toMap());
  }

  // Update room
  Future<void> updateRoom(Room room) async {
    await _realtimeDB.updateData('$_roomsPath/${room.id}', room.toMap());
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    await _realtimeDB.deleteData('$_roomsPath/$roomId');
  }

  // Toggle light
  Future<void> toggleLight(Room room, bool status) async {
    // Update Firebase
    final updatedRoom = room.copyWith(lightStatus: status);
    await updateRoom(updatedRoom);

    // Send command to ESP32
    await _updateESPControl('light', status);
  }

  // Toggle door
  Future<void> toggleDoor(Room room, bool status) async {
    // Update Firebase
    final updatedRoom = room.copyWith(doorStatus: status);
    await updateRoom(updatedRoom);

    // Send command to ESP32
    await _updateESPControl('door', status);
  }

  // Update ESP32 control
  Future<void> _updateESPControl(String device, bool status) async {
    await _realtimeDB.updateData(_espControlPath, {
      device: status,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Listen to ESP32 status
  Stream<Map<String, dynamic>> getESPStatus() {
    return _realtimeDB.listenToData(_espControlPath).map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return <String, dynamic>{};
      }

      return Map<String, dynamic>.from(data);
    });
  }
}
