# Kiểm tra Backend Logs cho ESP32 Connection

## ⚠️ QUAN TRỌNG: Xem Backend Logs ngay khi ESP32 cố kết nối

### Khi ESP32 cố kết nối, backend sẽ log:

#### ✅ Nếu thấy log này:
```
🤝 WebSocket Handshake Request:
   URI: ws://192.168.1.9:8080/ws/iot?clientType=esp32
   Method: GET
   Headers: ...
   Remote Address: /192.168.1.10:xxxxx
✅ WebSocket handshake successful
🔌 New WebSocket connection attempt:
   URI: ws://192.168.1.9:8080/ws/iot?clientType=esp32
   Remote Address: /192.168.1.10:xxxxx
   Session ID: xxxxx
   Detected client type: esp32
✅ ESP32 connected successfully: xxxxx
```

**→ Backend nhận được request và accept connection**
- Nếu vẫn disconnect → Có thể là network issue sau khi connect
- Kiểm tra close code và reason trong logs

#### ❌ Nếu KHÔNG thấy log "🤝 WebSocket Handshake Request":
**→ ESP32 không đến được WebSocket endpoint**

Có thể do:
1. **WebSocket library không gửi đúng upgrade request**
   - Library version issue
   - Library bug
   - **Giải pháp:** Test từ browser trước

2. **Network/Firewall block WebSocket upgrade**
   - Router block WebSocket
   - Firewall block upgrade headers
   - **Giải pháp:** Test từ browser cùng network

3. **Path không đúng**
   - Backend không route đúng
   - **Giải pháp:** Verify WebSocketConfig

### Cách xem Backend Logs

#### Nếu backend chạy từ terminal:
```bash
# Xem logs real-time
tail -f logs/spring.log

# Hoặc nếu chạy với mvn
# Logs sẽ hiển thị trực tiếp trong terminal
```

#### Nếu backend chạy từ IDE:
- Xem Console/Logs window
- Tìm log bắt đầu với "🤝" hoặc "🔌"

#### Nếu backend chạy như service:
```bash
# Linux
journalctl -u your-service-name -f

# Mac (nếu dùng launchd)
log stream --predicate 'process == "java"' --level debug
```

## Test từ Browser

**Trước khi debug ESP32, test từ browser:**

1. Mở `BackEnd/test_websocket.html` trong browser
2. Nhập:
   - Server IP: `192.168.1.9`
   - Port: `8080`
   - Client Type: `ESP32`
3. Click "Connect"

**Kết quả:**
- ✅ Browser kết nối được → Backend OK, vấn đề ở ESP32/library
- ❌ Browser cũng không kết nối → Vấn đề ở backend/network

## Debug Steps

### Step 1: Xem Backend Logs
- Chạy ESP32 và xem backend logs ngay lập tức
- Ghi lại tất cả logs liên quan đến WebSocket

### Step 2: Test từ Browser
- Dùng `test_websocket.html`
- Verify backend hoạt động

### Step 3: So sánh
- Browser có kết nối được không?
- Backend có log handshake cho browser không?
- So sánh với ESP32

## Common Issues

### Issue 1: No Handshake Log
**Symptom:** ESP32 disconnect, backend không có log gì

**Causes:**
- WebSocket library không gửi upgrade request
- Network block
- Path sai

**Solution:**
- Test từ browser
- Kiểm tra WebSocket library version
- Verify network connectivity

### Issue 2: Handshake Log nhưng Disconnect ngay
**Symptom:** Backend log handshake nhưng ESP32 disconnect

**Causes:**
- Backend reject sau khi accept
- Network issue sau handshake
- Library issue

**Solution:**
- Xem close code trong backend logs
- Xem close reason
- Kiểm tra network stability

## Next Action

**NGAY BÂY GIỜ:**
1. Chạy ESP32
2. Xem backend logs ngay khi ESP32 cố kết nối
3. Ghi lại:
   - Có thấy "🤝 WebSocket Handshake Request" không?
   - Có error gì không?
   - Close code là gì?

**Sau đó:**
- Test từ browser
- So sánh kết quả
- Share logs để debug tiếp
