import 'package:flutter/material.dart';

class Room {
  final String id;
  final String name;
  final String icon;
  final String userId;
  final bool hasLights;
  final bool hasDoor;
  final bool lightStatus;
  final bool doorStatus;
  final int lightPin;
  final int doorPin;

  Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.userId,
    this.hasLights = true,
    this.hasDoor = true,
    this.lightStatus = false,
    this.doorStatus = false,
    this.lightPin = 0,
    this.doorPin = 0,
  });

  // Convert Room to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'userId': userId,
      'hasLights': hasLights,
      'hasDoor': hasDoor,
      'lightStatus': lightStatus,
      'doorStatus': doorStatus,
      'lightPin': lightPin,
      'doorPin': doorPin,
    };
  }

  // Create Room from Map (from Firebase)
  factory Room.fromMap(Map<String, dynamic> map, String docId) {
    return Room(
      id: docId,
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'living',
      userId: map['userId'] ?? '',
      hasLights: map['hasLights'] ?? true,
      hasDoor: map['hasDoor'] ?? true,
      lightStatus: map['lightStatus'] ?? false,
      doorStatus: map['doorStatus'] ?? false,
      lightPin: map['lightPin'] ?? 0,
      doorPin: map['doorPin'] ?? 0,
    );
  }

  // Create copy of Room with updated fields
  Room copyWith({
    String? id,
    String? name,
    String? icon,
    String? userId,
    bool? hasLights,
    bool? hasDoor,
    bool? lightStatus,
    bool? doorStatus,
    int? lightPin,
    int? doorPin,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
      hasLights: hasLights ?? this.hasLights,
      hasDoor: hasDoor ?? this.hasDoor,
      lightStatus: lightStatus ?? this.lightStatus,
      doorStatus: doorStatus ?? this.doorStatus,
      lightPin: lightPin ?? this.lightPin,
      doorPin: doorPin ?? this.doorPin,
    );
  }
}
