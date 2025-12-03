# ESP32 WebSocket Connection Fix - "[WSc] Disconnected!"

## Vấn đề: ESP32 liên tục disconnect

Từ log ESP32:
```
WiFi connected! IP: 192.168.1.10
[WSc] Disconnected!
[WSc] Disconnected!
[WSc] Disconnected!
```

## Nguyên nhân phổ biến

### 1. Backend không chạy hoặc không accessible
**Kiểm tra:**
```bash
# Từ máy chạy backend
curl http://localhost:8080/api/health

# Từ ESP32 network (hoặc máy khác cùng network)
curl http://BACKEND_IP:8080/api/health
```

**Khắc phục:**
- Đảm bảo backend đang chạy
- Kiểm tra IP backend đúng
- Kiểm tra ESP32 và backend cùng mạng WiFi

### 2. IP Address sai trong ESP32 code
**Kiểm tra ESP32 code:**
```cpp
// ❌ SAI - Dùng localhost
const char* server_ip = "localhost";

// ❌ SAI - IP không đúng
const char* server_ip = "192.168.1.1"; // IP router, không phải backend

// ✅ ĐÚNG - IP thực của máy chạy backend
const char* server_ip = "192.168.1.100"; // Thay bằng IP thực
```

**Cách tìm IP backend:**
```bash
# Mac/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig
```

### 3. Port bị chặn hoặc sai
**Kiểm tra:**
```bash
# Test port từ ESP32 network
telnet BACKEND_IP 8080
# hoặc
nc -zv BACKEND_IP 8080
```

**Khắc phục:**
- Kiểm tra firewall không chặn port 8080
- Đảm bảo ESP32 code dùng port 8080

### 4. ESP32 code thiếu `webSocket.loop()`
**Code đúng:**
```cpp
#include <WiFi.h>
#include <WebSocketsClient.h>

WebSocketsClient webSocket;

void setup() {
  Serial.begin(115200);
  
  // WiFi setup
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
  
  // WebSocket setup
  const char* server_ip = "192.168.1.100"; // IP backend
  webSocket.begin(server_ip, 8080, "/ws/iot?clientType=esp32");
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000); // Reconnect sau 5 giây
  
  Serial.println("WebSocket initialized");
}

void loop() {
  webSocket.loop(); // ⚠️ QUAN TRỌNG: Phải có dòng này!
  delay(10);
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("[WSc] Disconnected!");
      Serial.print("   Reason: ");
      if (length > 0) {
        Serial.println((char*)payload);
      } else {
        Serial.println("Unknown");
      }
      break;
      
    case WStype_CONNECTED:
      Serial.println("[WSc] Connected!");
      Serial.print("   URL: ");
      Serial.println((char*)payload);
      // Send ready message
      webSocket.sendTXT("ESP32 ready!");
      break;
      
    case WStype_TEXT:
      Serial.print("[WSc] Received: ");
      Serial.println((char*)payload);
      break;
      
    case WStype_ERROR:
      Serial.print("[WSc] Error: ");
      Serial.println((char*)payload);
      break;
  }
}
```

### 5. Reconnect interval quá ngắn
**Vấn đề:** ESP32 cố reconnect quá nhanh, không kịp xử lý

**Khắc phục:**
```cpp
webSocket.setReconnectInterval(5000); // 5 giây
// Không dùng giá trị quá nhỏ như 100ms
```

### 6. WebSocket URL sai format
**ĐÚNG:**
```cpp
String path = "/ws/iot?clientType=esp32";
webSocket.begin(server_ip, 8080, path);
```

**SAI:**
```cpp
// Có space
String path = "/ws/iot?clientType=esp32 "; // ❌

// Thiếu query parameter
String path = "/ws/iot"; // ❌

// Dùng http thay vì ws
String url = "http://192.168.1.100:8080/ws/iot"; // ❌
```

## Debug Step-by-Step

### Bước 1: Test HTTP Connection
```cpp
#include <HTTPClient.h>

void testHTTP() {
  HTTPClient http;
  String url = "http://192.168.1.100:8080/api/health";
  http.begin(url);
  
  int httpCode = http.GET();
  Serial.print("HTTP Code: ");
  Serial.println(httpCode);
  
  if (httpCode == 200) {
    Serial.println("✅ HTTP connection OK!");
    Serial.println(http.getString());
  } else {
    Serial.println("❌ HTTP connection failed!");
  }
  http.end();
}
```

### Bước 2: Kiểm tra Backend Logs
Khi ESP32 cố kết nối, backend sẽ log:
```
🤝 WebSocket Handshake Request:
   URI: ws://192.168.1.100:8080/ws/iot?clientType=esp32
   Remote Address: /192.168.1.10:xxxxx
✅ WebSocket handshake successful
🔌 New WebSocket connection attempt:
   ...
✅ ESP32 connected successfully
```

**Nếu không thấy log này:**
- ESP32 không đến được backend
- Kiểm tra IP/Port
- Kiểm tra firewall

**Nếu thấy handshake nhưng disconnect ngay:**
- Xem close code và reason trong logs
- Kiểm tra ESP32 code có gọi `loop()` không

### Bước 3: Test từ Browser
Mở `test_websocket.html` và test với cùng IP:
- Nếu browser kết nối được → Vấn đề ở ESP32 code
- Nếu browser cũng không kết nối → Vấn đề ở backend/network

### Bước 4: Kiểm tra Network
```bash
# Từ ESP32 network, ping backend
ping 192.168.1.100

# Test port
telnet 192.168.1.100 8080
```

## ESP32 Code Mẫu Hoàn Chỉnh

```cpp
#include <WiFi.h>
#include <WebSocketsClient.h>

// ===== CONFIGURATION =====
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* server_ip = "192.168.1.100"; // ⚠️ Thay bằng IP thực của backend
const uint16_t server_port = 8080;

WebSocketsClient webSocket;

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n=== ESP32 WebSocket Client ===");
  
  // Connect to WiFi
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected!");
    Serial.print("   IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    return;
  }
  
  // Test HTTP connection first
  Serial.println("\nTesting HTTP connection...");
  HTTPClient http;
  String httpUrl = "http://" + String(server_ip) + ":8080/api/health";
  http.begin(httpUrl);
  int httpCode = http.GET();
  if (httpCode == 200) {
    Serial.println("✅ HTTP connection OK!");
  } else {
    Serial.print("❌ HTTP failed: ");
    Serial.println(httpCode);
  }
  http.end();
  
  // Setup WebSocket
  Serial.println("\nSetting up WebSocket...");
  String wsPath = "/ws/iot?clientType=esp32";
  webSocket.begin(server_ip, server_port, wsPath);
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
  
  Serial.print("   Server: ");
  Serial.print(server_ip);
  Serial.print(":");
  Serial.println(server_port);
  Serial.print("   Path: ");
  Serial.println(wsPath);
  Serial.println("Waiting for connection...");
}

void loop() {
  webSocket.loop(); // ⚠️ CRITICAL: Must call this!
  delay(10);
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("\n[WSc] ❌ Disconnected!");
      if (length > 0) {
        Serial.print("   Reason: ");
        Serial.println((char*)payload);
      }
      break;
      
    case WStype_CONNECTED:
      Serial.println("\n[WSc] ✅ Connected!");
      Serial.print("   URL: ");
      Serial.println((char*)payload);
      // Send ready message
      webSocket.sendTXT("ESP32 ready!");
      break;
      
    case WStype_TEXT:
      Serial.print("\n[WSc] 📩 Received: ");
      Serial.println((char*)payload);
      break;
      
    case WStype_BIN:
      Serial.printf("[WSc] 📦 Received binary: %u bytes\n", length);
      break;
      
    case WStype_ERROR:
      Serial.print("\n[WSc] ❌ Error: ");
      Serial.println((char*)payload);
      break;
      
    case WStype_PING:
      Serial.println("[WSc] 🏓 Ping");
      break;
      
    case WStype_PONG:
      Serial.println("[WSc] 🏓 Pong");
      break;
  }
}
```

## Checklist

- [ ] Backend đang chạy (`curl http://BACKEND_IP:8080/api/health`)
- [ ] IP backend đúng trong ESP32 code
- [ ] ESP32 và backend cùng mạng WiFi
- [ ] Port 8080 không bị firewall chặn
- [ ] ESP32 code có `webSocket.loop()` trong `loop()`
- [ ] WebSocket URL đúng format: `/ws/iot?clientType=esp32`
- [ ] Reconnect interval hợp lý (5000ms)
- [ ] Test HTTP connection trước khi test WebSocket
- [ ] Xem backend logs khi ESP32 kết nối
- [ ] Test từ browser với `test_websocket.html`

## Vẫn không được?

1. **Kiểm tra Serial Monitor ESP32:**
   - Xem có error message gì không
   - Xem IP address đúng chưa
   - Xem có log gì khi disconnect không

2. **Kiểm tra Backend Logs:**
   - Xem có handshake request không
   - Xem close code và reason
   - Xem có error gì không

3. **Test Network:**
   - Ping từ ESP32 network
   - Test port với telnet/nc
   - Kiểm tra firewall rules

4. **Thử ESP32 code mẫu:**
   - Dùng code mẫu ở trên
   - Chỉ thay IP và WiFi credentials
   - Test từng bước
