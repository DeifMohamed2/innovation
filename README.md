# InnovaLife Smart Hub System

This system provides integration between a mobile app and various smart home components like lights, doors, and air conditioning. It's designed to run on ESP32 microcontrollers and supports real-time control and monitoring.

## Features

- Control room lights (on/off)
- Control doors (open/close via servo motors)
- Control air conditioning (via IR signals)
- Real-time status updates from the mobile app
- Automatic synchronization with Firebase database
- Support for both standard Python and MicroPython environments

## Setup

### Prerequisites

- ESP32 microcontroller
- Python or MicroPython environment
- Firebase project with Realtime Database
- Wi-Fi connection

### Hardware Setup

1. **Lights**: Connect LEDs or relays to the GPIO pins defined in `LIGHT_PINS`
2. **Doors**: Connect servo motors to the GPIO pins defined in `SERVO_PINS`
3. **AC Control**: Connect an IR LED to the pin defined in `IR_LED_PIN`
4. **Status LED**: Connect an LED to `LED_INDICATOR_PIN` for system status indication

### Software Setup

1. Create a Firebase project with Realtime Database if you don't already have one
2. Update the `FIREBASE_URL` and `FIREBASE_AUTH` in the code with your Firebase details
3. For standard Python environments, download your Firebase service account key and save it as `serviceAccountKey.json`
4. Update the Wi-Fi credentials (`WIFI_SSID` and `WIFI_PASSWORD`) in the code
5. Flash the code to your ESP32 or run it on your Python environment

## Usage

The system automatically:

1. Connects to Wi-Fi
2. Registers with Firebase (generates a unique system ID)
3. Loads room configurations from Firebase
4. Sets up real-time listeners for changes
5. Updates device status periodically
6. Blinks the status LED to indicate normal operation

## Firebase Database Structure

The system expects the following structure in your Firebase Realtime Database:

```
- systems/
  - {system_id}/
    - code: "ESP32_XXXXXX"
    - name: "System ESP32_XXXXXX"
    - status: "online"
    - created_at: timestamp
    - ac_status: boolean
    - last_seen: timestamp
- rooms/
  - {room_id}/
    - name: "Room Name"
    - hasLights: boolean
    - hasDoor: boolean
    - lightPin: number
    - doorPin: number
    - lightStatus: boolean
    - doorStatus: boolean
- esp_control/
  - ac: boolean
- esp_status/
  - ac: boolean
  - online: boolean
  - ip: string
  - last_update: timestamp
  - uptime_seconds: number
```

## Troubleshooting

- **LED Indicator**: The LED should blink to indicate the system is running
- **Wi-Fi Connection**: If the system fails to connect to Wi-Fi, check your credentials
- **Firebase Connection**: If updates aren't reflecting in real-time, check the Firebase connection
- **Hardware Issues**: Verify pin connections if hardware isn't responding correctly

## Mobile App Integration

This system works with the InnovaLife mobile app, which connects to the same Firebase database to provide a user interface for controlling the system.

## License

[MIT License](LICENSE)
