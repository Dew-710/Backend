-- Test script để verify bookingId integration trong order creation

-- 1. Tạo test data: user, table, booking
INSERT INTO users (username, email, password, role, created_at, updated_at)
VALUES ('test_customer', 'customer@test.com', '$2a$10$test', 'CUSTOMER', NOW(), NOW())
ON CONFLICT (username) DO NOTHING;

INSERT INTO restaurant_tables (table_name, capacity, status, created_at, updated_at)
VALUES ('TEST_TABLE_01', 4, 'VACANT', NOW(), NOW())
ON CONFLICT (table_name) DO NOTHING;

-- 2. Tạo booking
INSERT INTO bookings (customer_id, table_id, booking_date, booking_time, guests, status, booking_code, created_at, updated_at)
SELECT
    u.id,
    t.id,
    CURRENT_DATE + INTERVAL '1 day',
    '19:00:00'::time,
    4,
    'CONFIRMED',
    'TEST_BOOKING_001',
    NOW(),
    NOW()
FROM users u, restaurant_tables t
WHERE u.username = 'test_customer' AND t.table_name = 'TEST_TABLE_01';

-- 3. Test tạo order với bookingId
-- (Sẽ được test qua API call)

-- 4. Verify order được tạo với booking_id đúng
SELECT
    'Test Results:' as info,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN booking_id IS NOT NULL THEN 1 END) as orders_with_booking,
    COUNT(CASE WHEN booking_id IS NULL THEN 1 END) as orders_without_booking
FROM orders;

-- 5. Chi tiết order với booking
SELECT
    o.id as order_id,
    o.booking_id,
    b.booking_code,
    b.status as booking_status,
    o.status as order_status,
    o.created_at
FROM orders o
LEFT JOIN bookings b ON o.booking_id = b.id
WHERE o.booking_id IS NOT NULL
ORDER BY o.created_at DESC
LIMIT 5;