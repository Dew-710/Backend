#!/bin/bash

# Test WebSocket endpoint với curl
# Usage: ./test_websocket_endpoint.sh [BACKEND_IP]

BACKEND_IP=${1:-"192.168.1.9"}
PORT=8080

echo "Testing WebSocket endpoint: ws://$BACKEND_IP:$PORT/ws/iot?clientType=esp32"
echo ""

# Generate WebSocket key
WS_KEY=$(echo -n "test-key-$(date +%s)" | base64 | tr -d '\n')

echo "1. Testing HTTP endpoint first..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$BACKEND_IP:$PORT/api/health")
if [ "$HTTP_RESPONSE" == "200" ]; then
    echo "   ✅ HTTP connection OK"
else
    echo "   ❌ HTTP connection failed (code: $HTTP_RESPONSE)"
    exit 1
fi

echo ""
echo "2. Testing WebSocket upgrade request..."
echo "   (This will show if backend receives the upgrade request)"
echo ""

curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: $WS_KEY" \
  -H "Sec-WebSocket-Protocol: chat, superchat" \
  "http://$BACKEND_IP:$PORT/ws/iot?clientType=esp32" 2>&1 | head -30

echo ""
echo ""
echo "3. Check backend logs for:"
echo "   - '🤝 WebSocket Handshake Request'"
echo "   - Any error messages"
