/**
 * ESP32 Firebase LED Control with Servo Door
 * 
 * This sketch connects to Firebase Realtime Database and controls
 * an LED based on the value of 'esp_control/light' and a servo door
 * based on the value of 'esp_control/door'
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>

// Provide the token generation process info.
#include <addons/TokenHelper.h>
// Provide the RTDB payload printing info and other helper functions.
#include <addons/RTDBHelper.h>

// Pin definitions
#define LED_PIN 13
#define SERVO_PIN 4

// Wi-Fi credentials
#define WIFI_SSID "Orange-Othmanahmed"
#define WIFI_PASSWORD "Shaza2017"

// Firebase project API Key
#define API_KEY "AIzaSyDbArT6Ghvz3_MOF1avsRot5i9gjVb2ML8"

// Firebase Realtime Database URL
#define DATABASE_URL "https://smarthub-60812-default-rtdb.firebaseio.com/"

// Define Firebase Data object
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Servo object
Servo doorServo;

// Variable to save USER UID
String uid;

// Database paths to monitor
String lightPath = "esp_control/light";
String doorPath = "esp_control/door";

// Last time data was fetched (for polling interval)
unsigned long lastFetchTime = 0;
const unsigned long fetchInterval = 1000; // 1 second polling interval

// Connection status
bool isWifiConnected = false;
bool isFirebaseConnected = false;

// Current states
bool currentLightState = false;
bool currentDoorState = false;

void setup() {
  // Initialize Serial port
  Serial.begin(115200);
  Serial.println("begin");
  Serial.println("ESP32 Firebase LED Control with Servo Door");
  
  // Initialize LED pin as output
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW); // Turn off LED initially
  
  // Initialize Servo
  doorServo.attach(SERVO_PIN);
  doorServo.write(0); // Set servo to initial position (door closed)
  
  // Connect to Wi-Fi
  connectToWiFi();
  
  // Initialize Firebase
  initFirebase();
}

void loop() {
  // Check if Wi-Fi is still connected
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Wi-Fi disconnected. Attempting to reconnect...");
    connectToWiFi();
  }
  
  // Only proceed if Firebase is ready
  if (Firebase.ready()) {
    // Poll Firebase at the specified interval
    unsigned long currentMillis = millis();
    if (currentMillis - lastFetchTime >= fetchInterval) {
      lastFetchTime = currentMillis;
      readFirebaseData();
    }
  } else if (isWifiConnected && !isFirebaseConnected) {
    // If Wi-Fi is connected but Firebase isn't, try to reconnect Firebase
    Serial.println("Firebase not connected. Attempting to reconnect...");
    initFirebase();
  }
}

void connectToWiFi() {
  Serial.print("Connecting to Wi-Fi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  unsigned long startTime = millis();
  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - startTime > 10000) { // 10 second timeout
      Serial.println("\nFailed to connect to Wi-Fi. Please check credentials.");
      delay(5000);
      startTime = millis(); // Reset timer and try again
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
    Serial.print(".");
    delay(300);
  }
  
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  isWifiConnected = true;
}

void initFirebase() {
  Serial.println("Initializing Firebase...");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  auth.user.email = "deifm81@gmail.com";
  auth.user.password = "1qaz2wsx";

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void readFirebaseData() {
  // Read light status
  if (Firebase.RTDB.getBool(&fbdo, lightPath)) {
    // Successfully got light data
    currentLightState = fbdo.boolData();
    Serial.print("Light status: ");
    Serial.println(currentLightState ? "ON" : "OFF");
    
    // Control the LED
    digitalWrite(LED_PIN, currentLightState ? HIGH : LOW);
  } else {
    // Failed to get data
    Serial.print("Firebase light read failed: ");
    Serial.println(fbdo.errorReason());
    isFirebaseConnected = false;
  }
  
  // Read door status
  if (Firebase.RTDB.getBool(&fbdo, doorPath)) {
    // Successfully got door data
    bool doorStatus = fbdo.boolData();
    
    // Only control the servo if the state has changed
    if (doorStatus != currentDoorState) {
      currentDoorState = doorStatus;
      controlDoor(doorStatus);
    }
    
    Serial.print("Door status: ");
    Serial.println(doorStatus ? "OPEN" : "CLOSED");
  } else {
    // Failed to get data
    Serial.print("Firebase door read failed: ");
    Serial.println(fbdo.errorReason());
    isFirebaseConnected = false;
  }
}

void controlDoor(bool isOpen) {
  if (isOpen) {
    // Open the door (0 to 180 degrees)
    for (int pos = 180; pos >= 0; pos -= 5) {
      doorServo.write(pos);
      delay(15);  // Small delay for smooth movement
    }
  } else {
    // Close the door (180 to 0 degrees)
    for (int pos = 0; pos <= 180; pos += 5) {
      doorServo.write(pos);
      delay(15);  // Small delay for smooth movement
    }
  }
}