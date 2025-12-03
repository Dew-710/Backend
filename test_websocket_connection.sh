#!/bin/bash

# Test WebSocket connection to backend
# Usage: ./test_websocket_connection.sh [BACKEND_IP]

BACKEND_IP=${1:-"192.168.1.9"}
PORT=8080

echo "Testing WebSocket connection to $BACKEND_IP:$PORT"
echo ""

# Test HTTP first
echo "1. Testing HTTP endpoint..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$BACKEND_IP:$PORT/api/health")
if [ "$HTTP_RESPONSE" == "200" ]; then
    echo "   ✅ HTTP connection OK"
else
    echo "   ❌ HTTP connection failed (code: $HTTP_RESPONSE)"
    exit 1
fi

# Test WebSocket with wscat (if available)
if command -v wscat &> /dev/null; then
    echo ""
    echo "2. Testing WebSocket connection..."
    echo "   Connecting to: ws://$BACKEND_IP:$PORT/ws/iot?clientType=esp32"
    timeout 5 wscat -c "ws://$BACKEND_IP:$PORT/ws/iot?clientType=esp32" 2>&1 | head -20
else
    echo ""
    echo "2. Testing WebSocket connection..."
    echo "   ⚠️ wscat not installed. Install with: npm install -g wscat"
    echo "   Or use test_websocket.html in browser"
fi

echo ""
echo "3. Check backend logs for:"
echo "   - '🤝 WebSocket Handshake Request'"
echo "   - '✅ WebSocket handshake successful'"
echo "   - '✅ ESP32 connected successfully'"
