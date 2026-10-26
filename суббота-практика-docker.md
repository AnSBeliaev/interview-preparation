# Суббота. Postgres в Docker и четыре таблицы

Сначала 40 минут пишете DDL сами, по списку из [02-sql-ddl-типы.md](02-sql-ddl-типы.md). Ключ лежит в [практика/schema.sql](практика/schema.sql), данные для вечерних запросов — в [практика/seed.sql](практика/seed.sql), пример `ALTER` — в [практика/alter.sql](практика/alter.sql).

## Поднять базу

Нужен Docker Desktop. На этой машине команды `docker` сейчас нет, её ставят до практики: [Docker Desktop для Windows](https://docs.docker.com/desktop/setup/install/windows-install/). После установки откройте Docker Desktop и дождитесь, пока он напишет, что запущен. Команда из плана:

```bash
docker run --name pg -e POSTGRES_PASSWORD=pass -p 5432:5432 -d postgres
```

Пользователь по умолчанию `postgres`, пароль `pass`, порт `5432`, база `postgres`.

Если контейнер с именем `pg` уже есть:

```bash
docker start pg
```

Открыть консоль SQL:

```bash
docker exec -it pg psql -U postgres
```

Выход: `\q`. Список таблиц: `\dt`. Описание одной: `\d customers`.

Когда свою схему дописали и хотите сверить её с ключом, не переписывайте файл руками в консоль. Скопируйте его в контейнер. Путь подставьте свой, если папка лежит не здесь:

```powershell
docker cp "C:\Users\User\interview-preparation\практика\schema.sql" pg:/tmp/schema.sql
docker exec -it pg psql -U postgres -f /tmp/schema.sql
docker cp "C:\Users\User\interview-preparation\практика\seed.sql" pg:/tmp/seed.sql
docker exec -it pg psql -U postgres -f /tmp/seed.sql
docker cp "C:\Users\User\interview-preparation\практика\alter.sql" pg:/tmp/alter.sql
docker exec -it pg psql -U postgres -f /tmp/alter.sql
```

`alter.sql` запускают один раз: повторный `ADD CONSTRAINT` упадёт, это нормально.

Если порт 5432 занят, контейнер не встанет. Тогда либо остановите местный Postgres, либо поднимите учебный на другом порту (`-p 5433:5432`) и в воскресных скриптах поправьте `port`.

## Что должно получиться

Четыре таблицы магазина. Типы специально разложены так, чтобы за субботу встретить весь список.

`customers`

- `id bigint GENERATED ALWAYS AS IDENTITY` — первичный ключ
- `email varchar(320) NOT NULL UNIQUE`
- `full_name text NOT NULL`
- `phone varchar(64)` — может быть пустым
- `country_code char(2) NOT NULL DEFAULT 'RU'`
- `birth_date date`
- `is_active boolean NOT NULL DEFAULT true`
- `created_at timestamptz NOT NULL DEFAULT now()`

`products`

- `id integer GENERATED ALWAYS AS IDENTITY` — первичный ключ
- `sku varchar(64) NOT NULL UNIQUE`
- `title text NOT NULL`
- `price numeric(12, 2) NOT NULL` и `CHECK (price >= 0)`
- `weight_kg real`
- `rating double precision` и `CHECK` на диапазон 0…5 или `NULL`
- `stock smallint NOT NULL DEFAULT 0` — ограничение `CHECK (stock >= 0)` добавите через `ALTER`
- `attrs jsonb NOT NULL DEFAULT '{}'`
- `legacy_payload json`
- `external_id uuid NOT NULL DEFAULT gen_random_uuid()`

`orders`

- `id bigserial` — первичный ключ, чтобы рядом с `IDENTITY` потрогать `serial`
- `customer_id bigint NOT NULL REFERENCES customers (id) ON DELETE RESTRICT`
- `status varchar(32) NOT NULL DEFAULT 'new'` и `CHECK` по списку статусов
- `total_amount numeric(12, 2) NOT NULL DEFAULT 0` и `CHECK (total_amount >= 0)`
- `delivery_slot time`
- `ordered_at timestamp NOT NULL DEFAULT now()`
- `created_at timestamptz NOT NULL DEFAULT now()`
- `note text`

`order_items`

- `id bigint GENERATED ALWAYS AS IDENTITY` — первичный ключ
- `order_id bigint NOT NULL REFERENCES orders (id) ON DELETE CASCADE`
- `product_id integer REFERENCES products (id) ON DELETE SET NULL`
- `qty integer NOT NULL CHECK (qty > 0)`
- `price numeric(12, 2) NOT NULL CHECK (price >= 0)`

`product_id` специально без `NOT NULL`: иначе `ON DELETE SET NULL` объявить нельзя.

## Пять проверок в psql

Деньги:

```sql
SELECT 0.1::float8 + 0.2::float8 AS approx, 0.1::numeric + 0.2::numeric AS exact;
```

Пояс:

```sql
SHOW timezone;
SELECT now() AS with_zone, now()::timestamp AS wall_clock;
```

Ограничение не пускает кривую цену. Ожидаете ошибку `check constraint`:

```sql
INSERT INTO products (sku, title, price)
VALUES ('BAD', 'Брак', -1);
```

Внешний ключ не пускает заказ без клиента. Тоже ошибка:

```sql
INSERT INTO orders (customer_id, total_amount) VALUES (999999, 10);
```

Каскад и `SET NULL` проверьте на копии строк, которые не жалко. Удалите тестовый заказ и убедитесь, что его позиции исчезли. Удалите тестовый товар и убедитесь, что в позиции `product_id` стал `NULL`, а сама позиция осталась. Клиента с заказом удалить не получится: сработает `RESTRICT`.

После `ALTER` в `\d products` должно быть ограничение `products_stock_nonnegative`. Колонки `nickname` у клиента быть не должно: её добавляют и сразу удаляют, чтобы прошли оба действия.

Дальше вечер: [03-sql-запросы.md](03-sql-запросы.md). Индексы создаются там, в утренний `CREATE TABLE` их не прячьте, чтобы вечер был отдельным действием.
