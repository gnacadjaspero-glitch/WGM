#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <RTClib.h>
#include <Wire.h>
#include <Update.h>

// --- CONFIGURATION DU POINT D'ACCÈS (AP) ---
const char* ssid = "WGM";
const char* password = "CheatWinner@360";

// Configuration de l'IP du Boitier
IPAddress local_IP(192, 168, 100, 1);
IPAddress gateway(192, 168, 100, 1);
IPAddress subnet(255, 255, 255, 0);

// Clé complexe de sécurité
const String SECRET_KEY = "X9#kL2!vP5*qZ8$mN4@yT1";

WebServer server(80);
Preferences preferences;
RTC_DS3231 rtc;

const int PIN_POSTES[] = {12, 13, 14, 27, 26, 25, 33, 32, 4, 5};
const int NB_POSTES = 10;

struct Session {
  bool active = false;
  bool isCoupure = false;
  long remainsSeconds = 0; // Calculé et stocké en secondes
};

Session sessions[NB_POSTES];

bool isAuthorized() {
  if (server.hasArg("key") && server.arg("key") == SECRET_KEY) return true;
  server.send(401, "text/plain", "NON AUTORISE");
  return false;
}

void setup() {
  Serial.begin(115200);
  Wire.begin();

  if (!rtc.begin()) {
    Serial.println("RTC non trouvé !");
  }

  for (int i = 0; i < NB_POSTES; i++) {
    pinMode(PIN_POSTES[i], OUTPUT);
    digitalWrite(PIN_POSTES[i], HIGH); // Relais OFF
  }

  // Initialisation WiFi AP
  WiFi.softAPConfig(local_IP, gateway, subnet);
  WiFi.softAP(ssid, password);

  // Charger les sessions après coupure
  preferences.begin("wgm_sessions", false);
  for (int i = 0; i < NB_POSTES; i++) {
    String key = "p" + String(i);
    long lastRemains = preferences.getLong(key.c_str(), 0);

    if (lastRemains >= 600) { // Règle des 10 minutes (600 secondes)
      sessions[i].active = true;
      sessions[i].isCoupure = true;
      sessions[i].remainsSeconds = lastRemains;
    } else {
      preferences.putLong(key.c_str(), 0);
    }
  }

  server.on("/activate", []() {
    if(!isAuthorized()) return;
    int index = server.arg("id").substring(1).toInt() - 1;
    int minutes = server.arg("time").toInt();

    if (index >= 0 && index < NB_POSTES) {
      long addedSeconds = (long)minutes * 60;
      sessions[index].remainsSeconds += addedSeconds;
      sessions[index].active = true;
      sessions[index].isCoupure = false;
      digitalWrite(PIN_POSTES[index], LOW);
      saveSession(index);
      server.send(200, "text/plain", "OK");
    }
  });

  server.on("/resume", []() {
    if(!isAuthorized()) return;
    int index = server.arg("id").substring(1).toInt() - 1;
    if (index >= 0 && index < NB_POSTES && sessions[index].isCoupure) {
      sessions[index].isCoupure = false;
      digitalWrite(PIN_POSTES[index], LOW);
      server.send(200, "text/plain", "OK");
    }
  });

  server.on("/stop", []() {
    if(!isAuthorized()) return;
    int index = server.arg("id").substring(1).toInt() - 1;
    if (index >= 0 && index < NB_POSTES) {
      stopPoste(index);
      server.send(200, "text/plain", "OK");
    }
  });

  server.on("/status", []() {
    String json = "{ \"postes\": [";
    for (int i = 0; i < NB_POSTES; i++) {
      json += "{ \"id\": \"P" + String(i + 1) + "\", \"active\": " + String(sessions[i].active ? "true" : "false") +
              ", \"isCoupure\": " + String(sessions[i].isCoupure ? "true" : "false") +
              ", \"remains\": " + String(sessions[i].remainsSeconds) + " }";
      if (i < NB_POSTES - 1) json += ",";
    }
    json += "] }";
    server.send(200, "application/json", json);
  });

  server.on("/update", HTTP_POST, []() {
    server.sendHeader("Connection", "close");
    server.send(200, "text/plain", (Update.hasError()) ? "FAIL" : "OK");
    ESP.restart();
  }, []() {
    HTTPUpload& upload = server.upload();
    if (upload.status == UPLOAD_FILE_START) {
      Serial.printf("Update: %s\n", upload.filename.c_str());
      if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
        Update.printError(Serial);
      }
    } else if (upload.status == UPLOAD_FILE_WRITE) {
      if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
        Update.printError(Serial);
      }
    } else if (upload.status == UPLOAD_FILE_END) {
      if (Update.end(true)) {
        Serial.printf("Update Success: %u\nRebooting...\n", upload.totalSize);
      } else {
        Update.printError(Serial);
      }
    }
  });

  server.begin();
}

unsigned long lastTick = 0;
void loop() {
  server.handleClient();

  if (millis() - lastTick >= 1000) {
    lastTick = millis();
    for (int i = 0; i < NB_POSTES; i++) {
      if (sessions[i].active && !sessions[i].isCoupure) {
        sessions[i].remainsSeconds--;

        // Sauvegarde périodique (toutes les 60s pour économiser la flash ou RAM RTC)
        if (sessions[i].remainsSeconds % 60 == 0) saveSession(i);

        if (sessions[i].remainsSeconds <= 0) {
          stopPoste(i);
        }
      }
    }
  }
}

void stopPoste(int index) {
  sessions[index].active = false;
  sessions[index].isCoupure = false;
  sessions[index].remainsSeconds = 0;
  digitalWrite(PIN_POSTES[index], HIGH);
  saveSession(index);
}

void saveSession(int index) {
  String key = "p" + String(index);
  preferences.putLong(key.c_str(), sessions[index].remainsSeconds);
}
