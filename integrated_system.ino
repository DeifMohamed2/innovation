#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ESP32Servo.h>
#include <WiFi.h>
#include <FirebaseESP32.h>

// WiFi credentials
const char* ssid = "deif";
const char* password = "123456789";

// Firebase Realtime Database settings
#define FIREBASE_HOST "smarthub-60812-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "3umhMyRsTTO9bHHaufhOrIJbuUYesQ8VVu1y0jk6"
FirebaseData firebaseData;
FirebaseConfig firebaseConfig;
FirebaseAuth firebaseAuth;

// IR remote settings
const uint16_t kIrLedPin = 19;  // GPIO pin for IR LED
IRsend irsend(kIrLedPin);

// LED indicator pin
const int LED_INDICATOR_PIN = 2; // Change to an available GPIO pin on your ESP32

// Servo settings
#define MAX_SERVOS 5
Servo servos[MAX_SERVOS];  // Array to store servos
int servoPins[MAX_SERVOS] = {15, 2, 4, 5, 18}; // Default pins - will be updated from Firebase

// LED settings
#define MAX_LIGHTS 5
int lightPins[MAX_LIGHTS] = {13, 12, 14, 27, 26}; // Default pins - will be updated from Firebase

// IR signal data for AC control
#define RAW_DATA_LEN_ON 109
uint16_t rawDataOn[RAW_DATA_LEN_ON] = {
  510, 442, 508, 444, 510, 442, 508, 442,
  512, 440, 512, 440, 510, 442, 510, 442,
  510, 444, 508, 442, 510, 442, 510, 444,
  508, 1396, 510, 440, 512, 440, 512, 440,
  510, 442, 510, 442, 510, 442, 510, 442,
  510, 442, 510, 442, 508, 442, 510, 444,
  508, 1396, 510, 442, 510, 442, 510, 440,
  510, 442, 510, 442, 510, 442, 508, 442,
  510, 444, 508, 442, 510, 442, 510, 1394,
  510, 442, 510, 1394, 520, 1386, 510, 1394,
  508, 1396, 508, 1396, 510, 442, 514, 438,
  510, 440, 520, 432, 512, 1394, 520, 1386,
  520, 1386, 508, 1000
};

#define RAW_DATA_LEN_OFF RAW_DATA_LEN_ON
uint16_t rawDataOff[RAW_DATA_LEN_OFF] = {
  510, 442, 508, 444, 510, 442, 508, 442,
  512, 440, 512, 440, 510, 442, 510, 442,
  510, 444, 508, 442, 510, 442, 510, 444,
  508, 1396, 510, 440, 512, 440, 512, 440,
  510, 442, 510, 442, 510, 442, 510, 442,
  510, 442, 510, 442, 508, 442, 510, 444,
  508, 1396, 510, 442, 510, 442, 510, 440,
  510, 442, 510, 442, 510, 442, 508, 442,
  510, 444, 508, 442, 510, 442, 510, 1394,
  510, 442, 510, 1394, 520, 1386, 510, 1394,
  508, 1396, 508, 1396, 510, 442, 514, 438,
  510, 440, 520, 432, 512, 1394, 520, 1386,
  520, 1386, 508, 1000
};

// Timing variables
unsigned long lastLedToggle = 0;
unsigned long lastFirebaseCheck = 0;
unsigned long lastStatusUpdate = 0;

// Device states
bool acState = false;
bool lightStates[MAX_LIGHTS] = {false};
bool doorStates[MAX_SERVOS] = {false};
bool firebaseConnected = false;

// Room configuration maps
struct RoomConfig {
  String id;
  String name;
  bool hasLights;
  bool hasDoor;
  int lightPin;
  int doorPin;
  bool lightStatus;
  bool doorStatus;
};

RoomConfig rooms[10]; // Support up to 10 rooms
int roomCount = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n=== SmartHub System Starting ===");
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }
  Serial.println();
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Connected to WiFi with IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("Failed to connect to WiFi! Check credentials.");
  }
  
  // Initialize Firebase
  firebaseConfig.database_url = FIREBASE_HOST;
  firebaseConfig.api_key = FIREBASE_AUTH;
  
  Firebase.begin(&firebaseConfig, &firebaseAuth);
  Firebase.reconnectWiFi(true);
  
  // Test Firebase connection
  if (Firebase.ready()) {
    firebaseConnected = true;
    Serial.println("Successfully connected to Firebase!");
    
    // Set initial online status
    Firebase.setBool(firebaseData, "/esp_status/online", true);
    Firebase.setString(firebaseData, "/esp_status/ip", WiFi.localIP().toString());
    Firebase.setString(firebaseData, "/esp_status/last_boot", String(millis()));
  } else {
    Serial.println("Failed to connect to Firebase. Check credentials and internet connection.");
    Serial.println("Error: " + firebaseData.errorReason());
  }
  
  // Initialize IR sender
  irsend.begin();
  Serial.println("IR Sender Ready");
  
  // Initialize LED pins
  for (int i = 0; i < MAX_LIGHTS; i++) {
    pinMode(lightPins[i], OUTPUT);
    digitalWrite(lightPins[i], LOW);
    Serial.print("Initialized LED pin ");
    Serial.println(lightPins[i]);
  }
  
  // Initialize LED indicator pin
  pinMode(LED_INDICATOR_PIN, OUTPUT);
  Serial.println("LED indicator initialized on pin " + String(LED_INDICATOR_PIN));
  
  // Load room configurations
  if (firebaseConnected) {
    loadRoomConfigurations();
  } else {
    Serial.println("Skipping room configuration load due to Firebase connection issue");
  }

  // Initialize servos based on room configurations
  for (int i = 0; i < roomCount; i++) {
    if (rooms[i].hasDoor && rooms[i].doorPin >= 0) {
      int servoIndex = findServoIndexByPin(rooms[i].doorPin);
      if (servoIndex >= 0) {
        servos[servoIndex].attach(rooms[i].doorPin);
        servos[servoIndex].write(rooms[i].doorStatus ? 180 : 0);
        Serial.println("Initialized servo for room " + rooms[i].name + " on pin " + String(rooms[i].doorPin));
      }
    }
  }
  
  Serial.println("=== Setup completed ===");
}

void loop() {
  unsigned long currentMillis = millis();
  
  // Check Firebase connection and reconnect if needed
  if (!Firebase.ready()) {
    if (firebaseConnected) {
      Serial.println("Firebase connection lost. Attempting to reconnect...");
      firebaseConnected = false;
    }
    
    if (Firebase.ready()) {
      Serial.println("Firebase reconnected!");
      firebaseConnected = true;
      Firebase.setBool(firebaseData, "/esp_status/online", true);
    }
  }
  
  // Check Firebase for commands every 2 seconds
  if (currentMillis - lastFirebaseCheck >= 2000) {
    lastFirebaseCheck = currentMillis;
    
    if (firebaseConnected) {
      Serial.println("Checking for Firebase updates...");
      checkFirebaseCommands();
    }
  }
  
  // Update status to Firebase every 30 seconds
  if (currentMillis - lastStatusUpdate >= 30000) {
    lastStatusUpdate = currentMillis;
    
    if (firebaseConnected) {
      Serial.println("Updating device status to Firebase...");
      updateDeviceStatus();
    }
  }
  
  // LED indicator blink for system status
  if (currentMillis - lastLedToggle >= 1000) {
    lastLedToggle = currentMillis;
    static bool ledIndicatorState = false;
    ledIndicatorState = !ledIndicatorState;
    digitalWrite(LED_INDICATOR_PIN, ledIndicatorState ? HIGH : LOW);
  }
}

void loadRoomConfigurations() {
  Serial.println("Loading room configurations from Firebase...");
  
  if (Firebase.getJSON(firebaseData, "/rooms")) {
    FirebaseJson &json = firebaseData.jsonObject();
    size_t count = json.iteratorBegin();
    roomCount = 0;
    
    Serial.print("Found ");
    Serial.print(count);
    Serial.println(" rooms in database");
    
    for (size_t i = 0; i < count && i < 10; i++) {
      String key, value;
      int type = 0;
      
      json.iteratorGet(i, type, key, value);
      
      if (type == FirebaseJson::JSON_OBJECT) {
        FirebaseJson roomJson;
        roomJson.setJsonData(value);
        
        String roomId = key;
        rooms[roomCount].id = roomId;
        
        FirebaseJsonData roomData;
        
        roomJson.get(roomData, "name");
        rooms[roomCount].name = roomData.stringValue;
        
        roomJson.get(roomData, "hasLights");
        rooms[roomCount].hasLights = roomData.boolValue;
        
        roomJson.get(roomData, "hasDoor");
        rooms[roomCount].hasDoor = roomData.boolValue;
        
        roomJson.get(roomData, "lightPin");
        rooms[roomCount].lightPin = roomData.intValue;
        if (rooms[roomCount].lightPin <= 0) {
          rooms[roomCount].lightPin = lightPins[roomCount % MAX_LIGHTS]; // use default pin if not specified
        }
        
        roomJson.get(roomData, "doorPin");
        rooms[roomCount].doorPin = roomData.intValue;
        if (rooms[roomCount].doorPin <= 0) {
          rooms[roomCount].doorPin = servoPins[roomCount % MAX_SERVOS]; // use default pin if not specified
        }
        
        roomJson.get(roomData, "lightStatus");
        rooms[roomCount].lightStatus = roomData.boolValue;
        
        roomJson.get(roomData, "doorStatus");
        rooms[roomCount].doorStatus = roomData.boolValue;
        
        // Set initial states
        if (rooms[roomCount].hasLights) {
          pinMode(rooms[roomCount].lightPin, OUTPUT);
          digitalWrite(rooms[roomCount].lightPin, rooms[roomCount].lightStatus ? HIGH : LOW);
        }
        
        Serial.print("Loaded room: ");
        Serial.print(rooms[roomCount].name);
        Serial.print(" (ID: ");
        Serial.print(rooms[roomCount].id);
        Serial.println(")");
        
        Serial.print("  - Light: ");
        if (rooms[roomCount].hasLights) {
          Serial.print("YES (Pin: ");
          Serial.print(rooms[roomCount].lightPin);
          Serial.print(", Status: ");
          Serial.print(rooms[roomCount].lightStatus ? "ON" : "OFF");
          Serial.println(")");
        } else {
          Serial.println("NO");
        }
        
        Serial.print("  - Door: ");
        if (rooms[roomCount].hasDoor) {
          Serial.print("YES (Pin: ");
          Serial.print(rooms[roomCount].doorPin);
          Serial.print(", Status: ");
          Serial.print(rooms[roomCount].doorStatus ? "OPEN" : "CLOSED");
          Serial.println(")");
        } else {
          Serial.println("NO");
        }
        
        roomCount++;
      }
    }
    
    json.iteratorEnd();
    Serial.print("Total rooms loaded: ");
    Serial.println(roomCount);
  } else {
    Serial.println("Failed to load room configurations");
    Serial.println("Error: " + firebaseData.errorReason());
  }
}

int findRoomIndexById(String roomId) {
  for (int i = 0; i < roomCount; i++) {
    if (rooms[i].id == roomId) {
      return i;
    }
  }
  return -1;
}

int findServoIndexByPin(int pin) {
  for (int i = 0; i < MAX_SERVOS; i++) {
    if (servoPins[i] == pin) {
      return i;
    }
  }
  return -1;
}

void checkFirebaseCommands() {
  // First check for general ESP control commands
  if (Firebase.getBool(firebaseData, "/esp_control/ac")) {
    bool newAcState = firebaseData.boolData();
    if (newAcState != acState) {
      Serial.print("AC state change detected in Firebase: ");
      Serial.println(newAcState ? "ON" : "OFF");
      acState = newAcState;
      controlAC(acState);
    }
  } else {
    Serial.print("Failed to get AC state: ");
    Serial.println(firebaseData.errorReason());
  }
  
  // Then check each room for updates
  for (int i = 0; i < roomCount; i++) {
    String roomPath = "/rooms/" + rooms[i].id;
    
    // Check for light control
    if (rooms[i].hasLights) {
      if (Firebase.getBool(firebaseData, roomPath + "/lightStatus")) {
        bool newLightState = firebaseData.boolData();
        if (newLightState != rooms[i].lightStatus) {
          Serial.print("Light state change detected for room ");
          Serial.print(rooms[i].name);
          Serial.print(": ");
          Serial.println(newLightState ? "ON" : "OFF");
          rooms[i].lightStatus = newLightState;
          controlLight(i, newLightState);
        }
      } else {
        Serial.print("Failed to get light state for room ");
        Serial.print(rooms[i].name);
        Serial.print(": ");
        Serial.println(firebaseData.errorReason());
      }
    }
    
    // Check for door control
    if (rooms[i].hasDoor) {
      if (Firebase.getBool(firebaseData, roomPath + "/doorStatus")) {
        bool newDoorState = firebaseData.boolData();
        if (newDoorState != rooms[i].doorStatus) {
          Serial.print("Door state change detected for room ");
          Serial.print(rooms[i].name);
          Serial.print(": ");
          Serial.println(newDoorState ? "OPEN" : "CLOSED");
          rooms[i].doorStatus = newDoorState;
          controlDoor(i, newDoorState);
        }
      } else {
        Serial.print("Failed to get door state for room ");
        Serial.print(rooms[i].name);
        Serial.print(": ");
        Serial.println(firebaseData.errorReason());
      }
    }
  }
  
  Serial.println("Firebase check completed");
}

void updateDeviceStatus() {
  FirebaseJson statusJson;
  
  // Add AC status
  statusJson.set("ac", acState);
  
  // Add timestamp and device info
  statusJson.set("last_update", String(millis()));
  statusJson.set("uptime_seconds", millis() / 1000);
  statusJson.set("online", true);
  statusJson.set("ip", WiFi.localIP().toString());
  statusJson.set("wifi_strength", WiFi.RSSI());
  
  // Update overall ESP status
  if (Firebase.updateNode(firebaseData, "/esp_status", statusJson)) {
    Serial.println("Device status updated to Firebase successfully");
  } else {
    Serial.print("Failed to update device status: ");
    Serial.println(firebaseData.errorReason());
  }
  
  // Add room specific statuses
  for (int i = 0; i < roomCount; i++) {
    String roomId = rooms[i].id;
    bool updateSuccess = true;
    
    if (rooms[i].hasLights) {
      if (!Firebase.setBool(firebaseData, "/rooms/" + roomId + "/lightStatus", rooms[i].lightStatus)) {
        Serial.print("Failed to update light status for room ");
        Serial.print(rooms[i].name);
        Serial.print(": ");
        Serial.println(firebaseData.errorReason());
        updateSuccess = false;
      }
    }
    
    if (rooms[i].hasDoor) {
      if (!Firebase.setBool(firebaseData, "/rooms/" + roomId + "/doorStatus", rooms[i].doorStatus)) {
        Serial.print("Failed to update door status for room ");
        Serial.print(rooms[i].name);
        Serial.print(": ");
        Serial.println(firebaseData.errorReason());
        updateSuccess = false;
      }
    }
    
    if (updateSuccess) {
      Serial.print("Status for room ");
      Serial.print(rooms[i].name);
      Serial.println(" updated successfully");
    }
  }
}

void controlLight(int roomIndex, bool state) {
  if (roomIndex < 0 || roomIndex >= roomCount) return;
  
  RoomConfig& room = rooms[roomIndex];
  if (!room.hasLights) return;
  
  Serial.print("Setting light in room ");
  Serial.print(room.name);
  Serial.print(" to: ");
  Serial.println(state ? "ON" : "OFF");
  
  digitalWrite(room.lightPin, state ? HIGH : LOW);
  room.lightStatus = state;
  
  // Update Firebase immediately to reflect the change
  if (firebaseConnected) {
    if (Firebase.setBool(firebaseData, "/rooms/" + room.id + "/lightStatus", state)) {
      Serial.println("Light status updated in Firebase");
    } else {
      Serial.print("Failed to update light status in Firebase: ");
      Serial.println(firebaseData.errorReason());
    }
  }
}

void controlDoor(int roomIndex, bool state) {
  if (roomIndex < 0 || roomIndex >= roomCount) return;
  
  RoomConfig& room = rooms[roomIndex];
  if (!room.hasDoor) return;
  
  Serial.print("Setting door in room ");
  Serial.print(room.name);
  Serial.print(" to: ");
  Serial.println(state ? "OPEN" : "CLOSED");
  
  int servoIndex = findServoIndexByPin(room.doorPin);
  if (servoIndex >= 0) {
    servos[servoIndex].write(state ? 180 : 0);
    Serial.print("Servo at index ");
    Serial.print(servoIndex);
    Serial.print(" on pin ");
    Serial.print(room.doorPin);
    Serial.print(" set to ");
    Serial.println(state ? 180 : 0);
  } else {
    Serial.print("Error: Could not find servo index for pin ");
    Serial.println(room.doorPin);
  }
  
  room.doorStatus = state;
  
  // Update Firebase immediately to reflect the change
  if (firebaseConnected) {
    if (Firebase.setBool(firebaseData, "/rooms/" + room.id + "/doorStatus", state)) {
      Serial.println("Door status updated in Firebase");
    } else {
      Serial.print("Failed to update door status in Firebase: ");
      Serial.println(firebaseData.errorReason());
    }
  }
}

void controlAC(bool state) {
  Serial.print("Setting AC to: ");
  Serial.println(state ? "ON" : "OFF");
  
  // Send IR command to AC
  if (state) {
    irsend.sendRaw(rawDataOn, RAW_DATA_LEN_ON, 38);
    Serial.println("IR command sent to turn AC ON");
  } else {
    irsend.sendRaw(rawDataOff, RAW_DATA_LEN_OFF, 38);
    Serial.println("IR command sent to turn AC OFF");
  }
  
  // Update Firebase immediately to reflect the change
  if (firebaseConnected) {
    if (Firebase.setBool(firebaseData, "/esp_control/ac", state)) {
      Serial.println("AC status updated in Firebase");
    } else {
      Serial.print("Failed to update AC status in Firebase: ");
      Serial.println(firebaseData.errorReason());
    }
  }
} 