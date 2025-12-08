#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include "MAX30105.h"
#include "heartRate.h"
#include "spo2_algorithm.h"

// ==== WiFi CONFIG ====
const char* ssid = "relme";          // Ganti dengan nama WiFi
const char* password = "hahaha99";   // Ganti dengan password WiFi

// ==== MQTT CONFIG ====
const char* mqtt_server = "broker.mqtt.cool";
const int mqtt_port = 1883;

// MQTT Topics
const char* topic_heartrate = "pulseox/heartrate";
const char* topic_spo2 = "pulseox/spo2";
const char* topic_status = "pulseox/status";
const char* topic_data = "pulseox/data";        // Combined data in JSON
const char* topic_command = "pulseox/command";   // Subscribe for commands

// ==== OLED CONFIG ====
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// ==== MAX30102 OBJECT ====
MAX30105 particleSensor;

// ==== MQTT CLIENT ====
WiFiClient espClient;
PubSubClient mqttClient(espClient);

// ==== RESET BUTTON ====
#define BUTTON_PIN 15
bool buttonPressed = false;

// SpO2 Variables - Smaller buffer for faster response
int32_t bufferLength = 50;
int32_t spo2;
int8_t validSPO2;
int32_t heartRate;
int8_t validHeartRate;
uint32_t irBuffer[50];
uint32_t redBuffer[50];

// Averaging variables
#define MAX_ATTEMPTS 3
int validReadings = 0;
int totalHR = 0;
int totalSpO2 = 0;

// Final results
int finalHeartRate = 0;
int finalSpO2 = 0;
bool measurementComplete = false;

// Auto-reset timer
unsigned long measurementCompleteTime = 0;
const unsigned long AUTO_RESET_DELAY = 15000;

// Finger detection
unsigned long fingerRemovedTime = 0;
const unsigned long FINGER_REMOVED_DELAY = 3000;

// Sensor stabilization
unsigned long fingerDetectedTime = 0;
const unsigned long STABILIZATION_TIME = 5000;
bool sensorStabilized = false;

// Signal quality monitoring
long lastIRValue = 0;
bool signalStable = false;

// WiFi & MQTT status
bool wifiConnected = false;
bool mqttConnected = false;

// MQTT reconnect timer
unsigned long lastMqttReconnectAttempt = 0;

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);

  pinMode(BUTTON_PIN, INPUT_PULLUP);

  // ==== OLED INIT ====
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED not found!");
    while (1);
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  // ==== WiFi INIT ====
  connectWiFi();

  // ==== MQTT INIT ====
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setBufferSize(512);
  
  connectMQTT();

  Serial.println("Initializing MAX30102...");

  // ==== MAX30102 INIT ====
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found!");
    display.println("SENSOR ERROR!");
    display.display();
    publishStatus("ERROR: Sensor not found");
    while (1);
  }

  // Optimized configuration
  byte ledBrightness = 0x4F;
  byte sampleAverage = 4;
  byte ledMode = 2;
  byte sampleRate = 400;
  int pulseWidth = 411;
  int adcRange = 4096;

  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
  particleSensor.setPulseAmplitudeRed(0x4F);
  particleSensor.setPulseAmplitudeIR(0x4F);
  particleSensor.enableDIETEMPRDY();

  showWelcomeScreen();
  publishStatus("READY: Device initialized");
}

void loop() {
  // Maintain MQTT connection
  if (!mqttClient.connected()) {
    unsigned long now = millis();
    if (now - lastMqttReconnectAttempt > 5000) {
      lastMqttReconnectAttempt = now;
      if (connectMQTT()) {
        lastMqttReconnectAttempt = 0;
      }
    }
  } else {
    mqttClient.loop();
  }

  // Check reset button
  if (digitalRead(BUTTON_PIN) == LOW) {
    if (!buttonPressed) {
      buttonPressed = true;
      resetMeasurement();
      delay(300);
    }
  } else {
    buttonPressed = false;
  }

  // If measurement complete
  if (measurementComplete) {
    long irValue = particleSensor.getIR();
    unsigned long currentTime = millis();
    
    // Check if finger removed
    if (irValue < 30000) {
      if (fingerRemovedTime == 0) {
        fingerRemovedTime = currentTime;
      }
      
      if (currentTime - fingerRemovedTime >= FINGER_REMOVED_DELAY) {
        display.clearDisplay();
        display.setTextSize(1);
        display.setCursor(20, 28);
        display.println("Finger Off");
        display.display();
        publishStatus("Finger removed");
        delay(1000);
        resetMeasurement();
        return;
      }
    } else {
      fingerRemovedTime = 0;
    }
    
    // Auto reset after timeout
    if (currentTime - measurementCompleteTime >= AUTO_RESET_DELAY) {
      resetMeasurement();
      return;
    }
    
    displayFinalResults();
    delay(1000);
    return;
  }

  // ==============================
  // FINGER DETECTION & STABILIZATION
  // ==============================
  long irValue = particleSensor.getIR();
  
  if (irValue < 30000) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(15, 20);
    display.println("Place Finger");
    display.setCursor(25, 35);
    display.println("On Sensor");
    
    // Show WiFi/MQTT status
    display.setCursor(0, 55);
    if (wifiConnected && mqttConnected) {
      display.print("MQTT:OK");
    } else if (wifiConnected) {
      display.print("WiFi:OK");
    } else {
      display.print("Offline");
    }
    
    display.display();
    
    Serial.print("IR Value: ");
    Serial.println(irValue);
    
    sensorStabilized = false;
    fingerDetectedTime = 0;
    signalStable = false;
    delay(500);
    return;
  }

  // Finger detected, start stabilization
  if (!sensorStabilized) {
    if (fingerDetectedTime == 0) {
      fingerDetectedTime = millis();
      lastIRValue = irValue;
      Serial.println("Finger detected, stabilizing...");
      publishStatus("Finger detected, stabilizing...");
    }
    
    // Check signal stability
    long irChange = abs(irValue - lastIRValue);
    if (irChange < 1000) {
      if (!signalStable) {
        signalStable = true;
        Serial.println("Signal stable!");
      }
    } else {
      signalStable = false;
    }
    lastIRValue = irValue;
    
    unsigned long stabilizationElapsed = millis() - fingerDetectedTime;
    int secondsRemaining = (STABILIZATION_TIME - stabilizationElapsed) / 1000 + 1;
    
    display.clearDisplay();
    display.setTextSize(1);
    
    // Title
    display.setCursor(25, 5);
    display.println("DETECTED");
    
    // Signal status
    display.setCursor(0, 20);
    display.print("Signal: ");
    if (signalStable) {
      display.println("STABLE");
    } else {
      display.println("---");
    }
    
    // Countdown
    display.setCursor(0, 35);
    display.print("Wait: ");
    display.print(secondsRemaining);
    display.println("s");
    
    // Progress bar
    int progress = map(stabilizationElapsed, 0, STABILIZATION_TIME, 0, 108);
    display.drawRect(10, 52, 108, 8, SSD1306_WHITE);
    display.fillRect(10, 52, progress, 8, SSD1306_WHITE);
    
    display.display();
    
    if (stabilizationElapsed >= STABILIZATION_TIME && signalStable) {
      sensorStabilized = true;
      Serial.println("Sensor stabilized, starting measurement...");
      publishStatus("Starting measurement...");
    } else if (stabilizationElapsed >= STABILIZATION_TIME + 3000) {
      sensorStabilized = true;
      Serial.println("Force start measurement...");
    }
    
    delay(100);
    return;
  }

  // ==============================
  // MULTIPLE READINGS
  // ==============================
  Serial.println("\n=== STARTING MEASUREMENT ===");
  publishStatus("MEASURING: In progress");
  
  validReadings = 0;
  totalHR = 0;
  totalSpO2 = 0;
  
  for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    Serial.print("\nAttempt ");
    Serial.print(attempt);
    Serial.print("/");
    Serial.println(MAX_ATTEMPTS);
    
    // Show attempt progress
    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(15, 15);
    display.print("Measuring ");
    display.print(attempt);
    display.print("/");
    display.println(MAX_ATTEMPTS);
    display.setCursor(20, 35);
    display.println("Stay Still");
    display.display();
    
    // ==============================
    // READ SAMPLES
    // ==============================
    bool samplingSuccessful = true;
    for (int i = 0; i < bufferLength; i++) {
      unsigned long sampleStartTime = millis();
      
      while (!particleSensor.available()) {
        particleSensor.check();
        if (millis() - sampleStartTime > 1000) {
          Serial.println("Timeout reading sensor!");
          samplingSuccessful = false;
          break;
        }
      }
      
      if (!samplingSuccessful) break;
      
      redBuffer[i] = particleSensor.getRed();
      irBuffer[i] = particleSensor.getIR();
      particleSensor.nextSample();
      
      // Check if finger still present
      if (irBuffer[i] < 20000) {
        Serial.println("Finger removed during measurement!");
        display.clearDisplay();
        display.setTextSize(1);
        display.setCursor(15, 28);
        display.println("Finger Off!");
        display.display();
        publishStatus("ERROR: Finger removed during measurement");
        delay(2000);
        resetMeasurement();
        return;
      }
      
      // Progress update every 10 samples
      if (i % 10 == 0) {
        display.clearDisplay();
        display.setTextSize(1);
        display.setCursor(15, 10);
        display.print("Measuring ");
        display.print(attempt);
        display.print("/");
        display.println(MAX_ATTEMPTS);
        
        int progress = map(i, 0, bufferLength, 0, 100);
        display.setCursor(35, 25);
        display.print(progress);
        display.println("%");
        
        // Progress bar
        display.drawRect(10, 45, 108, 12, SSD1306_WHITE);
        display.fillRect(12, 47, map(i, 0, bufferLength, 0, 104), 8, SSD1306_WHITE);
        
        display.display();
      }
    }

    if (!samplingSuccessful) {
      Serial.println("Sampling failed, retrying...");
      continue;
    }

    // ==============================
    // CALCULATE SPO2 & HEART RATE
    // ==============================
    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(20, 28);
    display.println("Processing...");
    display.display();
    
    spo2 = 0;
    heartRate = 0;
    validSPO2 = 0;
    validHeartRate = 0;
    
    maxim_heart_rate_and_oxygen_saturation(
        irBuffer, bufferLength, redBuffer,
        &spo2, &validSPO2, &heartRate, &validHeartRate
    );

    // ==============================
    // VALIDATION
    // ==============================
    Serial.print("Raw HR: ");
    Serial.print(heartRate);
    Serial.print(" | Valid HR: ");
    Serial.println(validHeartRate);
    Serial.print("Raw SpO2: ");
    Serial.print(spo2);
    Serial.print(" | Valid SpO2: ");
    Serial.println(validSPO2);
    
    bool hrValid = (heartRate >= 30 && heartRate <= 220);
    bool spo2Valid = (spo2 >= 60 && spo2 <= 100);
    
    if (validHeartRate == 1 && validSPO2 == 1) {
      hrValid = true;
      spo2Valid = true;
    }
    
    if (hrValid && spo2Valid) {
      validReadings++;
      totalHR += heartRate;
      totalSpO2 += spo2;
      
      Serial.println("✓ Valid reading");
      
      display.clearDisplay();
      display.setTextSize(1);
      display.setCursor(30, 20);
      display.println("Valid!");
      display.setCursor(25, 35);
      display.print(validReadings);
      display.print("/");
      display.print(MAX_ATTEMPTS);
      display.display();
      delay(800);
    } else {
      Serial.println("✗ Invalid reading");
      
      display.clearDisplay();
      display.setTextSize(1);
      display.setCursor(25, 28);
      display.println("Retrying...");
      display.display();
      delay(1000);
    }
    
    delay(300);
  }

  // ==============================
  // CALCULATE AVERAGE & SAVE
  // ==============================
  Serial.print("\n=== FINAL RESULT ===");
  Serial.print("\nValid readings: ");
  Serial.print(validReadings);
  Serial.print("/");
  Serial.println(MAX_ATTEMPTS);
  
  if (validReadings >= 1) {
    finalHeartRate = totalHR / validReadings;
    finalSpO2 = totalSpO2 / validReadings;
    measurementComplete = true;
    measurementCompleteTime = millis();
    fingerRemovedTime = 0;
    
    Serial.print("Heart Rate (avg): ");
    Serial.print(finalHeartRate);
    Serial.println(" bpm");
    Serial.print("SpO2 (avg): ");
    Serial.print(finalSpO2);
    Serial.println(" %");
    Serial.println("===================\n");
    
    // Publish to MQTT
    publishMeasurement();
    
    displayFinalResults();
    
  } else {
    if (totalHR > 0 && totalSpO2 > 0) {
      finalHeartRate = totalHR / MAX_ATTEMPTS;
      finalSpO2 = totalSpO2 / MAX_ATTEMPTS;
      measurementComplete = true;
      measurementCompleteTime = millis();
      
      Serial.print("Using average of all data:");
      Serial.print("HR: ");
      Serial.print(finalHeartRate);
      Serial.print(" SpO2: ");
      Serial.println(finalSpO2);
      
      // Publish to MQTT
      publishMeasurement();
      
      displayFinalResults();
    } else {
      display.clearDisplay();
      display.setTextSize(1);
      display.setCursor(30, 15);
      display.println("Failed!");
      display.setCursor(0, 35);
      display.println("Clean sensor &");
      display.setCursor(15, 45);
      display.println("try again");
      display.display();
      
      publishStatus("ERROR: Measurement failed");
      
      Serial.println("Measurement completely failed!");
      Serial.println("Retrying in 3 seconds...\n");
      delay(3000);
      resetMeasurement();
    }
  }
}

// ==== WiFi Functions ====
void connectWiFi() {
  Serial.println("Connecting to WiFi...");
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(10, 20);
  display.println("Connecting WiFi");
  display.display();
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.println("\nWiFi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    
    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(15, 20);
    display.println("WiFi Connected!");
    display.setCursor(10, 35);
    display.print(WiFi.localIP());
    display.display();
    delay(2000);
  } else {
    wifiConnected = false;
    Serial.println("\nWiFi connection failed!");
    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(10, 28);
    display.println("WiFi Failed!");
    display.display();
    delay(2000);
  }
}

// ==== MQTT Functions ====
bool connectMQTT() {
  if (!wifiConnected) {
    Serial.println("WiFi not connected, skipping MQTT");
    return false;
  }
  
  Serial.print("Connecting to MQTT broker...");
  
  // Connect without username, password, or client ID
  if (mqttClient.connect("")) {
    mqttConnected = true;
    Serial.println("Connected!");
    
    // Subscribe to command topic
    mqttClient.subscribe(topic_command);
    Serial.print("Subscribed to: ");
    Serial.println(topic_command);
    
    publishStatus("ONLINE: Device connected");
    
    return true;
  } else {
    mqttConnected = false;
    Serial.print("Failed, rc=");
    Serial.println(mqttClient.state());
    return false;
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);
  
  // Handle commands
  if (String(topic) == topic_command) {
    if (message == "RESET") {
      Serial.println("Reset command received");
      resetMeasurement();
    } else if (message == "STATUS") {
      publishStatus("READY: Device online");
    }
  }
}

void publishMeasurement() {
  if (!mqttConnected) {
    Serial.println("MQTT not connected, skipping publish");
    return;
  }
  
  char hrMsg[10];
  char spo2Msg[10];
  char jsonMsg[200];
  
  // Publish individual topics
  sprintf(hrMsg, "%d", finalHeartRate);
  sprintf(spo2Msg, "%d", finalSpO2);
  
  mqttClient.publish(topic_heartrate, hrMsg, true);
  mqttClient.publish(topic_spo2, spo2Msg, true);
  
  // Publish combined JSON
  sprintf(jsonMsg, "{\"heartrate\":%d,\"spo2\":%d,\"quality\":%d,\"timestamp\":%lu}", 
          finalHeartRate, finalSpO2, validReadings, millis());
  mqttClient.publish(topic_data, jsonMsg, true);
  
  publishStatus("COMPLETE: Measurement published");
  
  Serial.println("Data published to MQTT:");
  Serial.print("  Heart Rate: ");
  Serial.println(hrMsg);
  Serial.print("  SpO2: ");
  Serial.println(spo2Msg);
  Serial.print("  JSON: ");
  Serial.println(jsonMsg);
}

void publishStatus(const char* status) {
  if (!mqttConnected) return;
  
  mqttClient.publish(topic_status, status);
  Serial.print("Status published: ");
  Serial.println(status);
}

void displayFinalResults() {
  display.clearDisplay();
  
  // Top border
  display.drawLine(0, 0, 128, 0, SSD1306_WHITE);
  display.drawLine(0, 1, 128, 1, SSD1306_WHITE);
  
  // Quality indicator
  display.setTextSize(1);
  display.setCursor(5, 5);
  display.print("Q:");
  display.print(validReadings);
  display.print("/");
  display.print(MAX_ATTEMPTS);
  
  // MQTT status
  display.setCursor(70, 5);
  if (mqttConnected) {
    display.print("MQTT:OK");
  } else {
    display.print("OFFLINE");
  }
  
  // Divider
  display.drawLine(0, 16, 128, 16, SSD1306_WHITE);
  
  // Heart Rate
  display.setTextSize(1);
  display.setCursor(5, 22);
  display.println("BPM");
  
  display.setTextSize(2);
  display.setCursor(45, 20);
  display.print(finalHeartRate);
  
  // Middle divider
  display.drawLine(0, 38, 128, 38, SSD1306_WHITE);
  
  // SpO2
  display.setTextSize(1);
  display.setCursor(5, 44);
  display.println("SpO2");
  
  display.setTextSize(2);
  display.setCursor(45, 42);
  display.print(finalSpO2);
  display.setTextSize(1);
  display.print("%");
  
  // Bottom border with countdown
  display.drawLine(0, 60, 128, 60, SSD1306_WHITE);
  
  unsigned long timeRemaining = AUTO_RESET_DELAY - (millis() - measurementCompleteTime);
  int secondsRemaining = timeRemaining / 1000;
  
  display.setTextSize(1);
  display.setCursor(90, 5);
  display.print(secondsRemaining);
  display.print("s");
  
  display.display();
}

void showWelcomeScreen() {
  display.clearDisplay();
  
  // Top border
  display.drawLine(0, 0, 128, 0, SSD1306_WHITE);
  display.drawLine(0, 1, 128, 1, SSD1306_WHITE);
  
  display.setTextSize(1);
  display.setCursor(10, 5);
  display.println("PULSE OXIMETER");
  
  // Middle section
  display.setTextSize(2);
  display.setCursor(10, 22);
  display.println("BPM+SpO2");
  
  display.setTextSize(1);
  display.setCursor(25, 45);
  display.println("Place Finger");
  
  // Connection status
  display.setCursor(0, 56);
  if (wifiConnected && mqttConnected) {
    display.print("MQTT: Connected");
  } else if (wifiConnected) {
    display.print("WiFi: Connected");
  } else {
    display.print("Offline Mode");
  }
  
  // Bottom border
  display.drawLine(0, 62, 128, 62, SSD1306_WHITE);
  display.drawLine(0, 63, 128, 63, SSD1306_WHITE);
  
  display.display();
  delay(2000);
}

void resetMeasurement() {
  Serial.println("\n=== RESET MEASUREMENT ===\n");
  
  measurementComplete = false;
  finalHeartRate = 0;
  finalSpO2 = 0;
  spo2 = 0;
  heartRate = 0;
  measurementCompleteTime = 0;
  fingerRemovedTime = 0;
  sensorStabilized = false;
  fingerDetectedTime = 0;
  validReadings = 0;
  totalHR = 0;
  totalSpO2 = 0;
  signalStable = false;
  
  publishStatus("RESET: Device ready");
  
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(35, 25);
  display.println("RESET");
  display.setCursor(25, 40);
  display.println("Ready...");
  display.display();
  
  delay(1500);
  showWelcomeScreen();
}