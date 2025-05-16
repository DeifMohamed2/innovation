#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ESP32Servo.h>
#include <WiFi.h>
#include <FirebaseESP32.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Firebase Realtime Database settings
#define FIREBASE_HOST "smarthub-60812-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "3umhMyRsTTO9bHHaufhOrIJbuUYesQ8VVu1y0jk6"
FirebaseData firebaseData;

// IR remote settings
const uint16_t kIrLedPin = 19;  // GPIO pin for IR LED
IRsend irsend(kIrLedPin);

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

// Device states
bool acState = false;
bool lightStates[MAX_LIGHTS] = {false};
bool doorStates[MAX_SERVOS] = {false};

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
  Serial.begin(9600);
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Connected to WiFi with IP: ");
  Serial.println(WiFi.localIP());
  
  // Initialize Firebase
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);
  Serial.println("Connected to Firebase");
  
  // Initialize IR sender
  irsend.begin();
  Serial.println("IR Sender Ready");
  
  // Initialize LED pins
  for (int i = 0; i < MAX_LIGHTS; i++) {
    pinMode(lightPins[i], OUTPUT);
    digitalWrite(lightPins[i], LOW);
  }
  Serial.println("LEDs initialized");
  
  // Load room configurations
  loadRoomConfigurations();

  // Initialize servos based on room configurations
  for (int i = 0; i < roomCount; i++) {
    if (rooms[i].hasDoor && rooms[i].doorPin >= 0) {
      int servoIndex = findServoIndexByPin(rooms[i].doorPin);
      if (servoIndex >= 0) {
        servos[servoIndex].attach(rooms[i].doorPin);
        servos[servoIndex].write(rooms[i].doorStatus ? 180 : 0);
      }
    }
  }
  Serial.println("Servos initialized");
  
  Serial.println("Setup completed");
}

void loop() {
  unsigned long currentMillis = millis();
  
  // Check Firebase for commands every 2 seconds
  if (currentMillis - lastFirebaseCheck >= 2000) {
    lastFirebaseCheck = currentMillis;
    checkFirebaseCommands();
  }
  
  // LED indicator blink for system status
  if (currentMillis - lastLedToggle >= 1000) {
    lastLedToggle = currentMillis;
    static bool ledIndicatorState = false;
    ledIndicatorState = !ledIndicatorState;
    digitalWrite(LED_BUILTIN, ledIndicatorState ? HIGH : LOW);
  }
}

void loadRoomConfigurations() {
  if (Firebase.getJSON(firebaseData, "/rooms")) {
    FirebaseJson &json = firebaseData.jsonObject();
    FirebaseJsonData jsonData;
    size_t count = json.iteratorBegin();
    roomCount = 0;
    
    for (size_t i = 0; i < count && i < 10; i++) {
      json.iteratorGet(i, jsonData);
      if (jsonData.type == "object") {
        FirebaseJson roomJson;
        jsonData.getJSON(roomJson);
        
        String roomId = jsonData.key;
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
        Serial.println(rooms[roomCount].name);
        roomCount++;
      }
    }
    
    json.iteratorEnd();
    Serial.print("Total rooms loaded: ");
    Serial.println(roomCount);
  } else {
    Serial.println("Failed to load room configurations");
    Serial.println(firebaseData.errorReason());
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
      acState = newAcState;
      controlAC(acState);
    }
  }
  
  // Then check each room for updates
  for (int i = 0; i < roomCount; i++) {
    String roomPath = "/rooms/" + rooms[i].id;
    
    // Check for light control
    if (rooms[i].hasLights) {
      if (Firebase.getBool(firebaseData, roomPath + "/lightStatus")) {
        bool newLightState = firebaseData.boolData();
        if (newLightState != rooms[i].lightStatus) {
          rooms[i].lightStatus = newLightState;
          controlLight(i, newLightState);
        }
      }
    }
    
    // Check for door control
    if (rooms[i].hasDoor) {
      if (Firebase.getBool(firebaseData, roomPath + "/doorStatus")) {
        bool newDoorState = firebaseData.boolData();
        if (newDoorState != rooms[i].doorStatus) {
          rooms[i].doorStatus = newDoorState;
          controlDoor(i, newDoorState);
        }
      }
    }
  }
  
  // Update device status back to Firebase
  updateDeviceStatus();
}

void updateDeviceStatus() {
  FirebaseJson statusJson;
  
  // Add AC status
  statusJson.set("ac", acState);
  
  // Add timestamp
  statusJson.set("last_update", String(millis()));
  
  // Add room specific statuses
  for (int i = 0; i < roomCount; i++) {
    String roomId = rooms[i].id;
    if (rooms[i].hasLights) {
      Firebase.setBool(firebaseData, "/rooms/" + roomId + "/lightStatus", rooms[i].lightStatus);
    }
    if (rooms[i].hasDoor) {
      Firebase.setBool(firebaseData, "/rooms/" + roomId + "/doorStatus", rooms[i].doorStatus);
    }
  }
  
  // Update overall ESP status
  Firebase.updateNode(firebaseData, "/esp_status", statusJson);
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
  }
  room.doorStatus = state;
}

void controlAC(bool state) {
  Serial.print("Setting AC to: ");
  Serial.println(state ? "ON" : "OFF");
  
  // Send IR command to AC
  if (state) {
    irsend.sendRaw(rawDataOn, RAW_DATA_LEN_ON, 38);
  } else {
    irsend.sendRaw(rawDataOff, RAW_DATA_LEN_OFF, 38);
  }
} 