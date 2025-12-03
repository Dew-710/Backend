# ESP32 Quick Start Guide

## Vấn đề: ESP32 không thể kết nối tới backend

### Bước 1: Kiểm tra IP Address của Backend

**Trên máy chạy backend (Mac/Linux):**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Trên máy chạy backend (Windows):**
```bash
ipconfig
```

Tìm IP address trong mạng local (thường bắt đầu với `192.168.x.x` hoặc `10.0.x.x`)

**Ví dụ:** Nếu IP là `192.168.1.100`, thì WebSocket URL sẽ là:
```
ws://192.168.1.100:8080/ws/iot?clientType=esp32
```

### Bước 2: Test WebSocket Connection

**Option 1: Dùng test_websocket.html**
1. Mở file `BackEnd/test_websocket.html` trong browser
2. Nhập IP của backend
3. Click "Connect"
4. Xem có kết nối được không

**Option 2: Dùng wscat (command line)**
```bash
npm install -g wscat
wscat -c ws://192.168.1.100:8080/ws/iot?clientType=esp32
```

**Option 3: Dùng curl để test HTTP endpoint trước**
```bash
curl http://192.168.1.100:8080/v3/api-docs
```

### Bước 3: Code ESP32 mẫu

```cpp
#include <WiFi.h>
#include <WebSocketsClient.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Backend server IP (KHÔNG dùng localhost!)
const char* server_ip = "192.168.1.100";  // Thay bằng IP thực của bạn
const uint16_t server_port = 8080;

WebSocketsClient webSocket;

void setup() {
  Serial.begin(115200);
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("WiFi connected! IP: ");
  Serial.println(WiFi.localIP());
  
  // Connect to WebSocket
  String ws_url = "/ws/iot?clientType=esp32";
  webSocket.begin(server_ip, server_port, ws_url);
  webSocket.onEvent(webSocketEvent);
  
  Serial.println("Attempting WebSocket connection...");
}

void loop() {
  webSocket.loop();
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("WebSocket Disconnected");
      break;
      
    case WStype_CONNECTED:
      Serial.println("WebSocket Connected!");
      Serial.print("URL: ");
      Serial.println((char*)payload);
      // Send ready message
      webSocket.sendTXT("ESP32 ready!");
      break;
      
    case WStype_TEXT:
      Serial.print("Received: ");
      Serial.println((char*)payload);
      
      // Handle QR code image chunks
      String message = String((char*)payload);
      if (message.startsWith("IMG|")) {
        // Process image chunk
        handleImageChunk(message);
      } else if (message.startsWith("CONNECTED|")) {
        Serial.println("Server confirmed connection!");
      }
      break;
      
    case WStype_ERROR:
      Serial.print("WebSocket Error: ");
      Serial.println((char*)payload);
      break;
  }
}

void handleImageChunk(String chunk) {
  // Parse: IMG|1/3|base64data...
  // Implement your image decoding logic here
  Serial.println("Received image chunk");
}
```

### Bước 4: Debug Checklist

- [ ] ESP32 đã kết nối WiFi thành công
- [ ] Backend đang chạy (kiểm tra logs)
- [ ] IP address đúng (không dùng localhost)
- [ ] Port 8080 không bị firewall chặn
- [ ] WebSocket URL đúng format: `ws://IP:8080/ws/iot?clientType=esp32`
- [ ] Xem logs backend khi ESP32 kết nối

### Bước 5: Xem Logs Backend

Khi ESP32 kết nối, backend sẽ log:
```
🔌 New WebSocket connection attempt:
   URI: ws://192.168.1.100:8080/ws/iot?clientType=esp32
   Remote Address: /192.168.1.101:xxxxx
   Session ID: xxxxx
   Detected client type: esp32
✅ ESP32 connected successfully: xxxxx
```

Nếu không thấy log này, có nghĩa là:
- ESP32 chưa kết nối được
- Firewall đang chặn
- IP address sai
- Backend không chạy

### Bước 6: Test từ ESP32 Serial Monitor

1. Upload code lên ESP32
2. Mở Serial Monitor (115200 baud)
3. Xem logs:
   - WiFi connection status
   - WebSocket connection attempts
   - Error messages (nếu có)

### Common Issues

**Issue 1: "Connection refused"**
- Kiểm tra backend có đang chạy không
- Kiểm tra IP address đúng chưa
- Kiểm tra port 8080

**Issue 2: "Connection timeout"**
- Kiểm tra ESP32 và backend có cùng mạng WiFi không
- Kiểm tra firewall
- Thử ping từ ESP32 tới backend IP

**Issue 3: "WebSocket handshake failed"**
- Kiểm tra URL format đúng chưa
- Kiểm tra query parameter `clientType=esp32`
- Xem logs backend để biết lỗi cụ thể

### Need Help?

1. Xem logs backend: `tail -f logs/spring.log`
2. Test với `test_websocket.html`
3. Kiểm tra Serial Monitor ESP32
4. Verify network connectivity: `ping BACKEND_IP`
