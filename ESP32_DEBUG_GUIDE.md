# ESP32 Debug Guide - HTTP Request Parsing Errors

## Lỗi: "Invalid character found in the HTTP protocol"

Lỗi này xảy ra khi ESP32 gửi HTTP request không đúng format. Đây là các nguyên nhân phổ biến và cách khắc phục:

### Nguyên nhân phổ biến

1. **ESP32 code gửi plain HTTP thay vì WebSocket**
   - WebSocket cần HTTP Upgrade header
   - Kiểm tra ESP32 code có dùng WebSocket library đúng không

2. **URL có ký tự không hợp lệ**
   - Có space hoặc ký tự đặc biệt trong URL
   - URL không được encode đúng

3. **WebSocket library trên ESP32 không đúng**
   - Dùng library không hỗ trợ WebSocket đúng chuẩn
   - Version library cũ hoặc có bug

### Cách khắc phục

#### Bước 1: Test HTTP Connection trước

Trước khi test WebSocket, test HTTP endpoint đơn giản:

```cpp
#include <WiFi.h>
#include <HTTPClient.h>

const char* ssid = "YOUR_WIFI";
const char* password = "YOUR_PASSWORD";
const char* server_ip = "192.168.1.100"; // Thay bằng IP thực

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected!");
  
  // Test HTTP endpoint
  HTTPClient http;
  String url = "http://" + String(server_ip) + ":8080/api/health";
  http.begin(url);
  
  int httpCode = http.GET();
  if (httpCode == 200) {
    Serial.println("✅ HTTP connection OK!");
    Serial.println(http.getString());
  } else {
    Serial.print("❌ HTTP Error: ");
    Serial.println(httpCode);
  }
  http.end();
}

void loop() {
  // Your code here
}
```

#### Bước 2: Kiểm tra WebSocket Code

Đảm bảo ESP32 code đúng:

```cpp
#include <WiFi.h>
#include <WebSocketsClient.h>

WebSocketsClient webSocket;

void setup() {
  // ... WiFi setup ...
  
  // ✅ ĐÚNG: Dùng WebSocket library
  String ws_url = "/ws/iot?clientType=esp32";
  webSocket.begin(server_ip, server_port, ws_url);
  webSocket.onEvent(webSocketEvent);
  
  // ❌ SAI: Không dùng HTTPClient cho WebSocket
  // HTTPClient http;
  // http.begin("http://..."); // SAI!
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_CONNECTED:
      Serial.println("WebSocket Connected!");
      break;
    case WStype_DISCONNECTED:
      Serial.println("WebSocket Disconnected");
      break;
    case WStype_ERROR:
      Serial.print("WebSocket Error: ");
      Serial.println((char*)payload);
      break;
  }
}
```

#### Bước 3: Kiểm tra URL Format

**ĐÚNG:**
```
ws://192.168.1.100:8080/ws/iot?clientType=esp32
```

**SAI:**
```
ws://192.168.1.100:8080/ws/iot?clientType=esp32  // Có space ở cuối
http://192.168.1.100:8080/ws/iot?clientType=esp32  // Dùng http thay vì ws
ws://192.168.1.100:8080/ws/iot?clientType = esp32  // Có space quanh =
```

#### Bước 4: Dùng WebSocket Library đúng

**Khuyến nghị:** Dùng `WebSocketsClient` từ `markus-loebinger/WebSockets`

```cpp
// Install từ Arduino Library Manager:
// WebSockets by Markus Sattler

#include <WebSocketsClient.h>

WebSocketsClient webSocket;

void setup() {
  webSocket.begin(server_ip, 8080, "/ws/iot?clientType=esp32");
  webSocket.onEvent(webSocketEvent);
}

void loop() {
  webSocket.loop(); // Quan trọng: phải gọi loop()
}
```

### Test Endpoints

Backend cung cấp các endpoint test:

1. **HTTP Health Check:**
   ```bash
   curl http://192.168.1.100:8080/api/health
   ```

2. **Test Endpoint:**
   ```bash
   curl http://192.168.1.100:8080/api/test
   ```

3. **WebSocket Test:**
   - Dùng `test_websocket.html` trong browser
   - Hoặc `wscat -c ws://192.168.1.100:8080/ws/iot?clientType=esp32`

### Debug Steps

1. **Kiểm tra Serial Monitor ESP32:**
   - Xem có lỗi gì không
   - Xem URL được gửi đi
   - Xem response từ server

2. **Kiểm tra Backend Logs:**
   - Xem có log WebSocket handshake không
   - Xem có lỗi gì không

3. **Test từ Browser:**
   - Mở `test_websocket.html`
   - Test với cùng IP và port
   - Xem có kết nối được không

4. **Kiểm tra Network:**
   ```bash
   # Từ ESP32 network, ping backend
   ping 192.168.1.100
   
   # Test port
   telnet 192.168.1.100 8080
   ```

### Common Mistakes

1. **Dùng HTTPClient thay vì WebSocket:**
   ```cpp
   // ❌ SAI
   HTTPClient http;
   http.begin("http://.../ws/iot");
   
   // ✅ ĐÚNG
   WebSocketsClient ws;
   ws.begin(server_ip, 8080, "/ws/iot?clientType=esp32");
   ```

2. **Quên gọi loop():**
   ```cpp
   void loop() {
     webSocket.loop(); // Phải có dòng này!
   }
   ```

3. **URL có space hoặc ký tự đặc biệt:**
   ```cpp
   // ❌ SAI
   String url = "/ws/iot?clientType=esp32 "; // Space ở cuối
   
   // ✅ ĐÚNG
   String url = "/ws/iot?clientType=esp32";
   ```

4. **Dùng localhost thay vì IP:**
   ```cpp
   // ❌ SAI
   webSocket.begin("localhost", 8080, "/ws/iot");
   
   // ✅ ĐÚNG
   webSocket.begin("192.168.1.100", 8080, "/ws/iot");
   ```

### Still Having Issues?

1. Kiểm tra ESP32 Serial Monitor
2. Kiểm tra Backend logs
3. Test với `test_websocket.html` trước
4. Verify network connectivity
5. Thử với ESP32 code mẫu đơn giản nhất
