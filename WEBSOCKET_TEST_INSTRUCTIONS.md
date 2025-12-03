# WebSocket Test Instructions

## ⚠️ Lỗi: "Invalid request" khi test từ browser

Lỗi này có nghĩa là browser đang gửi HTTP request thay vì WebSocket upgrade request.

## Cách test đúng

### Option 1: Mở file qua HTTP server (KHUYẾN NGHỊ)

1. **Từ thư mục BackEnd, chạy HTTP server:**
   ```bash
   cd BackEnd
   python3 -m http.server 8000
   # hoặc
   npx http-server -p 8000
   ```

2. **Mở browser và truy cập:**
   ```
   http://localhost:8000/test_websocket.html
   ```

3. **Nhập thông tin:**
   - Server IP: `192.168.1.9`
   - Port: `8080`
   - Client Type: `ESP32`

4. **Click "Connect"**

### Option 2: Mở trực tiếp từ file system

**Lưu ý:** Một số browser có thể block WebSocket từ file:// protocol.

1. Mở `test_websocket.html` trực tiếp
2. Nếu không hoạt động, dùng Option 1

### Option 3: Test từ browser console

Mở browser console (F12) và chạy:

```javascript
const ws = new WebSocket('ws://192.168.1.9:8080/ws/iot?clientType=esp32');

ws.onopen = () => {
    console.log('✅ Connected!');
    ws.send('ESP32 ready!');
};

ws.onmessage = (event) => {
    console.log('📩 Received:', event.data);
};

ws.onerror = (error) => {
    console.error('❌ Error:', error);
};

ws.onclose = (event) => {
    console.log('🔌 Closed:', event.code, event.reason);
};
```

## Kiểm tra Backend Logs

Khi test từ browser, backend sẽ log:

```
🤝 WebSocket Handshake Request:
   URI: ws://192.168.1.9:8080/ws/iot?clientType=esp32
   Method: GET
   Headers: ...
✅ WebSocket handshake successful
🔌 New WebSocket connection attempt:
   ...
✅ ESP32 connected successfully
```

**Nếu KHÔNG thấy log này:**
- Browser không gửi được WebSocket upgrade request
- Có thể là CORS hoặc security issue
- Kiểm tra browser console (F12) để xem error

## Troubleshooting

### Error: "Invalid request"
- Browser đang gửi HTTP GET thay vì WebSocket upgrade
- **Giải pháp:** Mở file qua HTTP server (Option 1)

### Error: "Connection refused"
- Backend không chạy hoặc IP sai
- **Giải pháp:** Kiểm tra backend đang chạy và IP đúng

### Error: "WebSocket connection failed"
- Network issue hoặc firewall
- **Giải pháp:** Kiểm tra network và firewall

### No error nhưng không connect
- Xem backend logs
- Kiểm tra browser console
- Verify WebSocket URL đúng

## Next Steps

1. **Test từ browser với HTTP server** (Option 1)
2. **Xem backend logs** khi browser cố kết nối
3. **Xem browser console** (F12) để xem error chi tiết
4. **So sánh với ESP32** - nếu browser OK nhưng ESP32 không → Library issue
