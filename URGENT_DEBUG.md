# ⚠️ URGENT: Debug WebSocket Connection

## Tình trạng hiện tại

✅ HTTP test thành công
❌ WebSocket disconnect ngay (không có close reason)

## 🔴 QUAN TRỌNG: Kiểm tra Backend Logs NGAY

### Khi ESP32 cố kết nối, bạn CẦN xem backend logs:

**Mở terminal/console nơi backend đang chạy và xem:**

#### Scenario 1: KHÔNG có log gì
```
(Backend không log gì khi ESP32 cố kết nối)
```

**→ ESP32 không đến được WebSocket endpoint**
- WebSocket library không gửi đúng upgrade request
- Network/firewall block
- **Giải pháp:** Test từ browser trước

#### Scenario 2: Có log handshake nhưng reject
```
🤝 WebSocket Handshake Request:
   URI: ws://192.168.1.9:8080/ws/iot?clientType=esp32
❌ WebSocket handshake failed: [error message]
```

**→ Backend reject handshake**
- Xem error message để biết lý do
- Có thể là CORS, security, hoặc config issue

#### Scenario 3: Handshake thành công nhưng disconnect ngay
```
🤝 WebSocket Handshake Request:
   ...
✅ WebSocket handshake successful
🔌 New WebSocket connection attempt:
   ...
✅ ESP32 connected successfully
🔌 Client disconnected:
   Close Code: 1006
   Close Reason: ...
```

**→ Kết nối thành công nhưng disconnect ngay**
- Xem close code và reason
- Có thể là network issue sau khi connect

## Test từ Browser (QUAN TRỌNG)

**Trước khi debug ESP32, test từ browser:**

1. Mở file: `BackEnd/test_websocket.html`
2. Nhập:
   - Server IP: `192.168.1.9`
   - Port: `8080`
   - Client Type: `ESP32`
3. Click "Connect"

**Kết quả sẽ cho biết:**
- ✅ Browser kết nối được → Backend OK, vấn đề ở ESP32/library
- ❌ Browser cũng không → Vấn đề ở backend/network

## Quick Test Commands

### Test HTTP (đã OK)
```bash
curl http://192.168.1.9:8080/api/health
```

### Test WebSocket với wscat (nếu có)
```bash
wscat -c ws://192.168.1.9:8080/ws/iot?clientType=esp32
```

### Test WebSocket với curl
```bash
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" \
  http://192.168.1.9:8080/ws/iot?clientType=esp32
```

## Action Items

### NGAY BÂY GIỜ:

1. **Xem Backend Logs**
   - Chạy ESP32
   - Xem backend console/terminal
   - Ghi lại TẤT CẢ logs liên quan đến WebSocket
   - Đặc biệt tìm: "🤝", "🔌", "❌"

2. **Test từ Browser**
   - Mở `test_websocket.html`
   - Test với IP `192.168.1.9`
   - Ghi lại kết quả

3. **Chia sẻ kết quả**
   - Backend logs (có/không có handshake request)
   - Browser test (kết nối được/không)
   - Bất kỳ error message nào

## Possible Issues

### Issue 1: WebSocket Library không gửi upgrade request
**Symptom:** Backend không có log gì

**Solution:**
- Test từ browser
- Nếu browser OK → Library issue
- Thử library version khác

### Issue 2: Backend reject handshake
**Symptom:** Backend log handshake nhưng có error

**Solution:**
- Xem error message
- Kiểm tra CORS config
- Kiểm tra security config

### Issue 3: Network/Firewall
**Symptom:** HTTP OK nhưng WebSocket không

**Solution:**
- Test từ browser cùng network
- Kiểm tra firewall rules
- Test với wscat/curl

## Next Steps

Sau khi có backend logs và browser test results, chúng ta sẽ biết chính xác vấn đề ở đâu và cách fix.

**VUI LÒNG CHIA SẺ:**
1. Backend logs khi ESP32 cố kết nối
2. Browser test result
3. Bất kỳ error message nào
