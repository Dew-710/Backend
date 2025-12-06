-- Script để sửa chữa missing booking_id trong bảng orders
-- Chỉ cập nhật booking_id khi bàn đã được đặt trước và order được tạo trong khung giờ booking

-- Bước 1: Tìm và cập nhật booking_id cho orders có bàn đã được booking
UPDATE orders
SET booking_id = b.id
FROM bookings b
WHERE orders.booking_id IS NULL
  AND orders.table_id = b.table_id
  AND b.status IN ('CONFIRMED', 'CHECKED_IN')
  -- Kiểm tra order_time nằm trong khoảng thời gian booking (cùng ngày và trong vòng 2 giờ sau thời gian booking)
  AND DATE(orders.order_time) = b.date
  AND orders.order_time >= (b.date + b.time)
  AND orders.order_time <= (b.date + b.time + INTERVAL '2 hours');

-- Bước 2: Hiển thị kết quả sau khi update
SELECT
    o.id as order_id,
    o.table_id,
    o.booking_id,
    o.order_time,
    b.id as booking_id_from_booking,
    b.date,
    b.time,
    b.status as booking_status,
    b.booking_code
FROM orders o
LEFT JOIN bookings b ON o.booking_id = b.id
WHERE o.booking_id IS NOT NULL
ORDER BY o.id;

-- Bước 3: Kiểm tra những orders vẫn còn thiếu booking_id
SELECT
    o.id as order_id,
    o.table_id,
    o.order_time,
    o.status,
    'No booking found' as note
FROM orders o
WHERE o.booking_id IS NULL
ORDER BY o.id;