SET client_encoding TO 'UTF8';

INSERT INTO customers (email, full_name, phone, country_code, birth_date, is_active)
VALUES
    ('anna@example.com', 'Анна Иванова', '+79990000001', 'RU', '1994-04-12', true),
    ('boris@example.com', 'Борис Петров', NULL, 'RU', NULL, true),
    ('no-orders@example.com', 'Без заказов', NULL, 'RU', NULL, false);

INSERT INTO products (sku, title, price, weight_kg, rating, stock, attrs, legacy_payload)
VALUES
    ('SKU-1', 'Чайник', 1990.50, 1.2, 4.5, 5, '{"color": "red", "volume_l": 1.7}', '{"color": "red"}'),
    ('SKU-2', 'Кружка', 350.00, 0.3, 4.9, 20, '{"color": "white"}', NULL),
    ('SKU-3', 'Тарелка', 120.00, 0.4, NULL, 40, '{}', NULL);

INSERT INTO orders (customer_id, status, total_amount, delivery_slot, note)
VALUES
    (1, 'paid', 2340.50, '10:30', 'позвонить за час'),
    (1, 'new', 120.00, NULL, NULL),
    (2, 'cancelled', 350.00, '18:00', NULL);

INSERT INTO order_items (order_id, product_id, qty, price)
VALUES
    (1, 1, 1, 1990.50),
    (1, 2, 1, 350.00),
    (2, 3, 1, 120.00),
    (3, 2, 1, 350.00);
