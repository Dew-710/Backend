-- Script tạo dữ liệu test cho chức năng check-in
-- Tạo bàn đang đợi check-in và booking tương ứng

-- 1. Tạo bàn test (nếu chưa có)
INSERT INTO restaurant_tables (table_name, capacity, status, created_at, updated_at)
VALUES ('CHECKIN_TEST_01', 4, 'PENDING_CHECKIN', NOW(), NOW())
ON CONFLICT (table_name) DO UPDATE SET
    status = 'PENDING_CHECKIN',
    updated_at = NOW();

-- 2. Tạo user test (customer)
INSERT INTO users (username, email, password, role, created_at, updated_at)
VALUES ('test_customer_checkin', 'checkin_test@example.com', '$2a$10$test', 'CUSTOMER', NOW(), NOW())
ON CONFLICT (username) DO NOTHING;

-- 3. Tạo booking đã được duyệt (CONFIRMED)
INSERT INTO bookings (customer_id, table_id, booking_date, booking_time, guests, status, booking_code, created_at, updated_at)
SELECT
    u.id,
    t.id,
    CURRENT_DATE,
    '18:00:00'::time,
    4,
    'CONFIRMED',
    'TEST_CHECKIN_' || EXTRACT(epoch FROM NOW())::text,
    NOW(),
    NOW()
FROM users u, restaurant_tables t
WHERE u.username = 'test_customer_checkin'
  AND t.table_name = 'CHECKIN_TEST_01'
ON CONFLICT DO NOTHING;

-- 4. Verify dữ liệu
SELECT
    'Test Data Created:' as status,
    COUNT(*) as total_tables,
    COUNT(CASE WHEN status = 'PENDING_CHECKIN' THEN 1 END) as pending_checkin_tables,
    COUNT(CASE WHEN b.status = 'CONFIRMED' THEN 1 END) as confirmed_bookings
FROM restaurant_tables t
LEFT JOIN bookings b ON t.id = b.table_id;

-- 5. Chi tiết bàn đang chờ check-in
SELECT
    t.id as table_id,
    t.table_name,
    t.status as table_status,
    t.capacity,
    b.id as booking_id,
    b.booking_code,
    b.status as booking_status,
    b.booking_date,
    b.booking_time,
    b.guests,
    u.username as customer_name
FROM restaurant_tables t
LEFT JOIN bookings b ON t.id = b.table_id AND b.status = 'CONFIRMED'
LEFT JOIN users u ON b.customer_id = u.id
WHERE t.status = 'PENDING_CHECKIN';