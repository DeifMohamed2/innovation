#include <WiFi.h>
#include <FirebaseESP32.h>
#include <ESP32Servo.h> // Include the ESP32Servo library

// Replace with your network credentials
const char* ssid = "Nada's iPhone";
const char* password = "12345678";

// Replace with your Firebase project credentials
#define FIREBASE_HOST "smarthub-60812-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "your_firebase_database_secret"  // Replace with your actual Firebase database secret

FirebaseData firebaseData;
FirebaseConfig firebaseConfig;
FirebaseAuth firebaseAuth;

// Define the GPIO pins
const int lightPin = 5;  // Light control pin
const int pcPin = 21;     // PC control pin
const int servoPin = 17;  // Servo control pin (GPIO 17)
const int tvPin = 23;     // TV control pin (GPIO 19)

// Create a Servo object
Servo doorServo;

void setup() {
  // Initialize Serial Monitor
  Serial.begin(115200);

  // Initialize Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to Wi-Fi");

  // Configure Firebase
  firebaseConfig.host = FIREBASE_HOST;
  firebaseConfig.signer.tokens.legacy_token = FIREBASE_AUTH;

  // Initialize Firebase
  Firebase.begin(&firebaseConfig, &firebaseAuth);
  Firebase.reconnectWiFi(true);

  // Set the GPIO pins as outputs
  pinMode(lightPin, OUTPUT);
  pinMode(pcPin, OUTPUT);
  pinMode(tvPin, OUTPUT);

  // Attach the servo to the specified pin
  doorServo.attach(servoPin, 500, 2500); // Specify PWM range (500-2500 µs)

  // Set the servo to its initial position
  doorServo.write(90); // Door is initially "off"
}

void loop() {
  // Check the light status in Firebase
  if (Firebase.getString(firebaseData, "/home/light")) {
    String lightStatus = firebaseData.stringData();
    
    // Print the status
    Serial.println("Light status: " + lightStatus);

    // Set the light pin based on the light status
    if (lightStatus == "on") {
      digitalWrite(lightPin, HIGH);
      Serial.println("Light ON - Pin 16 HIGH");
    } else if (lightStatus == "off") {
      digitalWrite(lightPin, LOW);
      Serial.println("Light OFF - Pin 16 LOW");
    }
  } else {
    // Handle error for light status
    Serial.println("Failed to get light status: " + firebaseData.errorReason());
  }

  // Check the PC status in Firebase
  if (Firebase.getString(firebaseData, "/home/pc")) {
    String pcStatus = firebaseData.stringData();
    
    // Print the status
    Serial.println("PC status: " + pcStatus);

    // Set the PC pin based on the PC status
    if (pcStatus == "on") {
      digitalWrite(pcPin, HIGH);
      Serial.println("PC ON - Pin 18 HIGH");
    } else if (pcStatus == "off") {
      digitalWrite(pcPin, LOW);
      Serial.println("PC OFF - Pin 18 LOW");
    }
  } else {
    // Handle error for PC status
    Serial.println("Failed to get PC status: " + firebaseData.errorReason());
  }

  // Check the door status in Firebase
  if (Firebase.getString(firebaseData, "/home/doors")) {
    String doorStatus = firebaseData.stringData();
    
    // Print the status
    Serial.println("Door status: " + doorStatus);

    // Set the servo position based on the door status
    if (doorStatus == "on") {
      doorServo.write(180); // Move servo to 180 degrees
      Serial.println("Door OPEN - Servo at 180 degrees");
    } else if (doorStatus == "off") {
      doorServo.write(90);  // Move servo to 90 degrees
      Serial.println("Door CLOSED - Servo at 90 degrees");
    }
  } else {
    // Handle error for door status
    Serial.println("Failed to get door status: " + firebaseData.errorReason());
  }

  // Check the TV status in Firebase
  if (Firebase.getString(firebaseData, "/home/tv")) {
    String tvStatus = firebaseData.stringData();
    
    // Print the status
    Serial.println("TV status: " + tvStatus);

    // Set the TV pin based on the TV status
    if (tvStatus == "on") {
      digitalWrite(tvPin, HIGH);
      Serial.println("TV ON - Pin 19 HIGH");
    } else if (tvStatus == "off") {
      digitalWrite(tvPin, LOW);
      Serial.println("TV OFF - Pin 19 LOW");
    }
  } else {
    // Handle error for TV status
    Serial.println("Failed to get TV status: " + firebaseData.errorReason());
  }

  // Delay to avoid frequent Firebase requests
  delay(2000);
}
 da code semester el fat lel maquette kolo omar 2aly hat7tageh