# InnovaLife Smart Home Integration

This project integrates Flutter, Firebase Realtime Database, and ESP32 for a complete smart home control system.

## Project Structure

- **Flutter App**: Front-end for controlling smart home devices
- **Firebase**: Real-time database for storing and syncing data
- **ESP32**: Controller for physical devices (lights, doors, AC, etc.)
- **ESP32 Simulator**: C program to simulate ESP32 behavior without physical hardware

## Setup Instructions

### 1. Firebase Setup

1. Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Realtime Database to your project
3. Copy the Firebase configuration into `/lib/backend/firebase/firebase_config.dart`
4. Upload the database rules from `/firebase/database.rules.json`

### 2. ESP32 Setup (Choose one)

#### Option A: Use the ESP32 Simulator (No hardware required)

1. Install required libraries: libcurl and libjson-c
2. Update the Firebase configuration in `esp_simulator.c`
3. Compile and run the simulator:
   ```
   make
   ./esp_simulator
   ```
4. See `ESP_SIMULATOR_GUIDE.md` for detailed instructions

#### Option B: Use Real ESP32 Hardware

1. Install required libraries in your Arduino IDE:
   - IRremoteESP8266
   - ESP32Servo
   - FirebaseESP32
2. Update the WiFi credentials and Firebase details in `integrated_system.ino`
3. Flash the code to your ESP32 device
4. Connect hardware components:
   - IR LED: GPIO 19
   - Servo motors: GPIO 15, 2, and 4
   - LED: GPIO 13

### 3. Flutter App Setup

1. Run `flutter pub get` to install dependencies
2. Connect the app to Firebase:
   ```
   flutterfire configure
   ```
3. Run the app:
   ```
   flutter run
   ```

## Usage

1. Login to the app
2. Navigate to the Smart Home section
3. Add rooms and control your smart home devices
4. Toggle lights and doors to see real-time control of your ESP32 device or simulator

## Firebase Schema

The Realtime Database is structured as follows:

```
/rooms/{roomId}
  - id: string
  - name: string
  - icon: string
  - userId: string
  - hasLights: boolean
  - hasDoor: boolean
  - lightStatus: boolean
  - doorStatus: boolean

/esp_control
  - light: boolean
  - door: boolean
  - ac: boolean
  - timestamp: number

/esp_status
  - light: boolean
  - door: boolean
  - ac: boolean
  - last_update: string
```

## Transitioning from Simulator to Real Hardware

When you're ready to move from the simulator to real hardware:

1. Study the conversion guide in `ESP_SIMULATOR_GUIDE.md`
2. Install the required Arduino libraries
3. Flash the `integrated_system.ino` file to your ESP32
4. Connect the hardware components as specified

The Firebase integration will work the same way with both the simulator and real hardware.

## Troubleshooting

1. **ESP32 not connecting to WiFi**: Check your WiFi credentials
2. **App not connecting to Firebase**: Verify your Firebase configuration
3. **Physical devices not responding**: Check hardware connections and ESP32 serial monitor
4. **Simulator issues**: See troubleshooting section in `ESP_SIMULATOR_GUIDE.md`

## Contributing

Feel free to contribute to this project by submitting pull requests or reporting issues.
