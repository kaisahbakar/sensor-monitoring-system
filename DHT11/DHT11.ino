#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

#define DHTPIN 4
#define DHTTYPE DHT11
#define RELAY_PIN 25

// WiFi Credentials
const char* ssid = "1C25A2-Maxis Fibre";
const char* password = "wq278dHnFc";

// API Endpoints
const char* insertURL = "https://humancc.site/nurkaisah/DHT11/bek_n/insert.php";
String deviceId = "ESP32_001";

// ⚠️ Replace this with dynamic loading (e.g., from EEPROM) if needed
int userId = 1;  // This should match the currently logged-in Flutter user

// Threshold Defaults
float tempThreshold = 26.0;
float humThreshold = 70.0;

DHT dht(DHTPIN, DHTTYPE);
unsigned long lastSendTime = 0;

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  dht.begin();

  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
}

String buildThresholdURL() {
  return "https://humancc.site/nurkaisah/DHT11/bek_n/get_thresholds.php?user_id=" + String(userId) + "&device_id=" + deviceId;
}

void fetchThresholds() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(buildThresholdURL());
    int httpCode = http.GET();

    if (httpCode == 200) {
      String payload = http.getString();
      Serial.println("Threshold response: " + payload);

      StaticJsonDocument<512> doc;
      DeserializationError error = deserializeJson(doc, payload);

      if (!error && doc["status"] == true) {
        tempThreshold = doc["thresholds"]["temp_threshold"].as<float>();
        humThreshold = doc["thresholds"]["humidity_threshold"].as<float>();

        Serial.println("Updated thresholds:");
        Serial.println("Temp Threshold: " + String(tempThreshold));
        Serial.println("Humidity Threshold: " + String(humThreshold));
      } else {
        Serial.println("JSON error or missing thresholds.");
      }
    } else {
      Serial.println("HTTP error: " + String(httpCode));
    }

    http.end();
  } else {
    Serial.println("WiFi not connected for threshold fetch.");
  }
}

void loop() {
  if (millis() - lastSendTime >= 10000) {
    fetchThresholds();  // Refresh thresholds every 10s

    float temp = dht.readTemperature();
    float hum = dht.readHumidity();

    if (!isnan(temp) && !isnan(hum)) {
      bool relayStatus = (temp > tempThreshold || hum > humThreshold);
      digitalWrite(RELAY_PIN, relayStatus ? HIGH : LOW);

      if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        http.begin(insertURL);
        http.addHeader("Content-Type", "application/json");

        String payload = "{\"temperature\":" + String(temp, 2) +
                         ",\"humidity\":" + String(hum, 2) +
                         ",\"relay_status\":\"" + (relayStatus ? "ON" : "OFF") + "\"," +
                         "\"device_id\":\"" + deviceId + "\"," +
                         "\"user_id\":" + String(userId) + "}";

        int httpResponseCode = http.POST(payload);
        String response = http.getString();

        Serial.println("POST response code: " + String(httpResponseCode));
        Serial.println("Response body: " + response);
        Serial.println("Payload sent: " + payload);

        http.end();
      } else {
        Serial.println("WiFi disconnected during POST.");
      }
    } else {
      Serial.println("Failed to read DHT11.");
    }

    lastSendTime = millis();
  }
}
