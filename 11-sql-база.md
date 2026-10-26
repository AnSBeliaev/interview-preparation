# Понедельник. SQL, базовый блок

2–3 часа, первым. Контейнер `pgstat`, не субботний `pg`. Таблица заказов здесь уже есть, у неё колонки `user_id` и `amount`. В магазине из [03-sql-запросы.md](03-sql-запросы.md) те же вещи называются `customer_id` и `total_amount`. Запросы оттуда в этот контейнер не копируют.

Консоль:

```powershell
docker start pgstat
docker exec -it pgstat psql -U postgres
```

Внутри `psql` описание заказа: `\d orders`. Выход: `\q`.

Четыре задачи в конце файла решаются без подсказок. Ответов под ними нет.

## 1. Вторая таблица для JOIN

Пользователи. Номер задаётся явно, не через `IDENTITY`: вставка ниже сама передаёт `id`.

```sql
CREATE TABLE users (
  id int PRIMARY KEY,
  name varchar(100) NOT NULL,
  email text UNIQUE,
  city text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

Десять тысяч строк. `generate_series(0, 10000)` даёт числа от 0 до 10000. `'user_' || g` склеивает текст и это число. Город берётся из списка четырёх значений, четвёртое — `NULL`.

```sql
INSERT INTO users (id, name, email, city)
SELECT g, 'user_' || g, 'user_' || g || '@mail.ru',
       (ARRAY['Москва','Ростов','Казань', NULL])[1 + floor(random()*4)::int]
FROM generate_series(0, 10000) g;
```

Два пользователя без заказов. Они нужны для `LEFT JOIN`.

```sql
INSERT INTO users (id, name) VALUES (20001, 'no_orders_1'), (20002, 'no_orders_2');
```

## 2. ALTER TABLE

```sql
ALTER TABLE users ADD COLUMN phone varchar(20);
ALTER TABLE users ALTER COLUMN phone TYPE text;
ALTER TABLE users RENAME COLUMN phone TO phone_number;
ALTER TABLE users DROP COLUMN phone_number;
ALTER TABLE users ALTER COLUMN city SET DEFAULT 'Москва';
```

Связь заказа с пользователем и запрет отрицательной суммы:

```sql
ALTER TABLE orders ADD CONSTRAINT orders_user_fk FOREIGN KEY (user_id) REFERENCES users (id);
ALTER TABLE orders ADD CONSTRAINT amount_positive CHECK (amount >= 0);
```

Проверка внешнего ключа. Ожидается ошибка: пользователя 99999 нет.

```sql
INSERT INTO orders (user_id, amount) VALUES (99999, 10);
```

Список колонок у `INSERT` поправьте, если `\d orders` покажет другие обязательные поля без значения по умолчанию.

## 3. WHERE

```sql
SELECT * FROM users WHERE city = 'Ростов' AND is_active;
SELECT * FROM users WHERE city IN ('Москва', 'Казань');
SELECT * FROM users WHERE city IS NULL;
SELECT * FROM users WHERE name LIKE 'user_1%';
```

`WHERE city = NULL` не возвращает строк. Пустое значение ищут через `IS NULL`.

`LIKE 'user_1%'` оставляет имена, которые начинаются с `user_1`. Знак `%` — любой хвост.

## 4. BETWEEN

Обе границы входят в диапазон.

```sql
SELECT * FROM orders WHERE amount BETWEEN 100 AND 200;
```

Ловушка с датой. У `timestamptz` полночь — это начало дня. Такой диапазон теряет весь день 31 января после `00:00`:

```sql
WHERE created_at BETWEEN '2026-01-01' AND '2026-01-31'
```

День 31 января целиком попадает сюда:

```sql
WHERE created_at >= '2026-01-01' AND created_at < '2026-02-01'
```

## 5. ORDER BY

```sql
SELECT * FROM orders ORDER BY amount DESC LIMIT 10;
SELECT * FROM users ORDER BY city NULLS LAST, name;
```

`DESC` ставит большие суммы сверху. `LIMIT 10` оставляет десять первых после сортировки. `NULLS LAST` отправляет пустой город в конец. Вторая колонка `name` сортирует людей внутри одного города.

## 6. JOIN

`JOIN` и `INNER JOIN` — одно и то же. В ответе только пары.

```sql
SELECT u.name, o.amount
FROM users u
JOIN orders o ON o.user_id = u.id
LIMIT 10;
```

`LEFT JOIN` оставляет всех пользователей. У кого заказа нет, колонки заказа пустые. Условие `o.id IS NULL` после соединения оставляет только таких:

```sql
SELECT u.id, u.name
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL;
```

В ответе будут `20001` и `20002`.

`RIGHT JOIN` сохраняет правую таблицу. На практике его почти не пишут: таблицы меняют местами и пишут `LEFT JOIN`. `FULL JOIN` оставляет строки с обеих сторон. `CROSS JOIN` клеит каждую строку левой таблицы с каждой строкой правой, условия `ON` нет. Его достаточно назвать.

## 7. GROUP BY и HAVING

```sql
SELECT status, count(*), sum(amount), avg(amount)
FROM orders
GROUP BY status;
```

```sql
SELECT u.city, count(o.id) AS orders_count
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.city
HAVING count(o.id) > 200000
ORDER BY orders_count DESC;
```

`WHERE` выкидывает строки до группировки. `HAVING` выкидывает уже готовые группы. Всё, что в `SELECT` написано без `count`, `sum` или `avg`, должно стоять в `GROUP BY`. Здесь это `status` и `u.city`.

## 8. Порядок выполнения

`FROM` → `JOIN` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `ORDER BY` → `LIMIT`

База собирает строки до `SELECT`. Псевдоним из `SELECT` в `WHERE` ещё не существует. В `ORDER BY` он уже есть: сортировка идёт после `SELECT`.

## Задачи

Без подсказок.

1. Топ-5 пользователей по сумме оплаченных заказов.
2. Количество заказов по месяцам за последний год. Месяц берётся так: `date_trunc('month', created_at)`.
3. Города, где средний чек больше 500.
4. Пользователи, у которых нет ни одного заказа со статусом `paid`.
