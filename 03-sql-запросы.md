# Суббота, вечер. Запросы и индексы

Таблицы уже есть: `customers`, `products`, `orders`, `order_items`. Данные — из `практика/seed.sql`. Если база пустая, сначала дойдите [суббота-практика-docker.md](суббота-практика-docker.md).

## Два порядка

У запроса два порядка. Их путают, потому что оба настоящие.

Порядок записи — как слова стоят в файле. Первое слово почти всегда `SELECT`. Так требует синтаксис: команда, которая возвращает строки, начинается с `SELECT`. Ниже идут `FROM`, `JOIN`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`. База читает текст целиком, сверху вниз, чтобы понять предложение. Это чтение текста, как чтение любого абзаца.

Порядок смысла — в какой последовательности эти части меняют набор строк. Его и проговаривают на собесе. Список наизусть:

`FROM` → `JOIN` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `ORDER BY` → `LIMIT`

`SELECT` в этом списке ближе к концу, хотя в файле он на первой строке. Слова в файле никто не переставляет. Переставляется только рассказ о том, что эти слова делают с данными.

Почему смысл идёт с `FROM`. Запрос описывает готовый ответ, а не программу из шагов. Первая строка называет колонки ответа. Чтобы эти колонки из чего-то собрать, базе сначала нужен набор строк. Набор строк дают таблицы, поэтому смысл начинается с `FROM`.

Дальше набор сужают и только потом оформляют:

1. `FROM` берёт строки одной таблицы.
2. `JOIN` приклеивает к ним строки другой таблицы. После этого шага в наборе уже колонки обеих таблиц.
3. `WHERE` выкидывает строки. Он видит колонки таблиц, в том числе приклеенные `JOIN`.
4. `GROUP BY` схлопывает оставшиеся строки в группы.
5. `HAVING` выкидывает целые группы. Суммы и количества к этому моменту уже посчитаны, поэтому их можно писать здесь.
6. `SELECT` из оставшегося набора берёт колонки. Слово после `AS` — псевдоним: имя этой колонки только в ответе на данный запрос. В таблице колонка остаётся со старым именем. Псевдоним рождается на этом шаге.
7. `ORDER BY` сортирует готовый ответ. Псевдоним из `SELECT` ему виден.
8. `LIMIT` отрезает верхние n строк после сортировки.

Коротко: до `SELECT` база собирает строки, на `SELECT` выбирает колонки, после `SELECT` укладывает ответ.

Проверка, что порядок смысла запомнен. Псевдоним из `SELECT` в `WHERE` не существует, в `ORDER BY` существует.

```sql
SELECT email AS почта
FROM customers
WHERE почта = 'anna@example.com';
```

База ответит `column "почта" does not exist`. К шагу `WHERE` псевдонима ещё нет. `почта` — имя колонки только в ответе. В таблице колонка называется `email`.

```sql
SELECT email AS почта
FROM customers
WHERE email = 'anna@example.com'
ORDER BY почта;
```

`WHERE` использует `email`. `ORDER BY` может использовать `почта`: сортировка идёт после `SELECT`.

Как читать глазами. `SELECT` на первой строке пропускают. Находят `FROM` и идут по списку выше. У каждого следующего слова спрашивают: что стало с набором строк. К `SELECT` возвращаются в конце: какие колонки из этого набора попадут в ответ.

Фраза: «Пишут с `SELECT`, смысл идёт с `FROM`. `WHERE` фильтрует строки, `SELECT` выбирает колонки уже собранного набора. Псевдоним из `SELECT` в `WHERE` не виден, в `ORDER BY` виден».

## SELECT, WHERE, ORDER BY, LIMIT

```sql
SELECT id, email, full_name
FROM customers
WHERE is_active = true
ORDER BY created_at DESC
LIMIT 20;
```

`WHERE` оставляет строки. `ORDER BY` сортирует уже оставшиеся. `LIMIT` берёт верхние n после сортировки.

`NULL` обычным равенством не находится:

```sql
SELECT id, full_name
FROM customers
WHERE phone IS NULL;
```

`WHERE phone = NULL` не вернёт строк.

## JOIN

`JOIN` и `INNER JOIN` — одно и то же. В ответе только те строки, у которых нашлась пара.

```sql
SELECT o.id, o.status, o.total_amount, c.email
FROM orders AS o
JOIN customers AS c ON c.id = o.customer_id
WHERE o.status = 'paid';
```

`LEFT JOIN` сохраняет левую таблицу. Если пары справа нет, правые колонки приходят `NULL`.

Клиенты и их заказы, включая клиента без заказов:

```sql
SELECT c.email, o.id AS order_id, o.status
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.id
ORDER BY c.email;
```

У `no-orders@example.com` колонка `order_id` будет `NULL`. При обычном `JOIN` эта строка пропадёт. Это и есть ответ «когда какой»: пара обязана существовать — `JOIN`; нужна и сторона без пары — `LEFT JOIN`, «левая» та таблица, которую нельзя потерять.

Клиенты, у которых заказов нет:

```sql
SELECT c.email
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.id
WHERE o.id IS NULL;
```

## GROUP BY, HAVING, агрегаты

Агрегаты, которые надо написать с ходу: `count`, `sum`, `avg`, плюс `min` и `max`, если попросят край.

```sql
SELECT status, count(*) AS orders_count, sum(total_amount) AS amount
FROM orders
GROUP BY status
ORDER BY amount DESC;
```

Всё, что в `SELECT` не внутри агрегата, стоит в `GROUP BY`.

`WHERE` фильтрует строки до группировки. `HAVING` фильтрует уже группы.

```sql
SELECT c.email, sum(o.total_amount) AS amount
FROM customers AS c
JOIN orders AS o ON o.customer_id = c.id
WHERE o.status = 'paid'
GROUP BY c.email
HAVING sum(o.total_amount) > 1000;
```

`count(*)` считает строки. `count(phone)` считает строки, где `phone` не `NULL`.

`avg(price)` по товарам:

```sql
SELECT avg(price) AS avg_price FROM products;
```

## Пять запросов без подглядывания

Ответы в конце файла.

1. Название и цена товаров дороже 300, по убыванию цены.
2. Email, статус и сумма заказа. Заказ без клиента в эту выборку не входит.
3. Все клиенты и число их заказов, в том числе ноль.
4. Статусы, в которых сумма `total_amount` больше 300.
5. Артикул, количество и цена позиции вместе с email клиента.

## Что такое индекс

Индекс — отдельная структура для поиска. Строка в таблице от него не заменяется. За чтение по условию, соединение и сортировку база платит меньше, за `INSERT` и `UPDATE` — больше: индекс тоже надо обновить. Поэтому индекс вешают на колонки, по которым реально ищут, а не на все подряд.

Первичный ключ и `UNIQUE` уже создают индекс. Внешний ключ индекс на ссылающейся колонке сам не создаёт. `orders.customer_id` стоит проиндексировать: по нему идёт `JOIN` и проверка `ON DELETE` у клиента.

```sql
CREATE INDEX orders_customer_id_idx ON orders (customer_id);
```

Пока не указали вид, это B-tree.

Индекс помогает, когда по нему отсекается заметная часть большой таблицы: равенство по ключу, диапазон дат, соединение по внешнему ключу, сортировка в том же порядке.

Индекс не помогает или его не выбирают, когда:

- таблица маленькая, дешевле прочитать её целиком;
- условие почти ничего не отсекает (`is_active = true` у таблицы, где активны почти все);
- нужен ведущий `%` в шаблоне: `LIKE '%чай'` по B-tree не ищется, `LIKE 'чай%'` ищется;
- колонку завернули в функцию: `WHERE lower(email) = ...`, а индекс построен по `email`, не по `lower(email)`.

На учебном магазине из четырёх строк разницы по времени не увидите. Смысл всё равно проговаривайте: индекс — про большую таблицу и выборочное условие.

Посмотреть, собирается ли база идти в индекс:

```sql
EXPLAIN
SELECT * FROM orders WHERE customer_id = 1;
```

`Index Scan` или `Bitmap Index Scan` значит, что индекс задействован. `Seq Scan` на крошечной таблице — нормальный выбор, не ошибка схемы.

## B-tree

B-tree (сбалансированное дерево) — индекс по умолчанию.

```sql
CREATE INDEX orders_customer_id_idx ON orders (customer_id);
```

Он обслуживает:

- равенство `=`;
- сравнение `<`, `<=`, `>`, `>=`;
- `BETWEEN`;
- `IN`;
- `ORDER BY` по этой колонке;
- префиксный поиск `LIKE 'abc%'`.

Для равенства, диапазона и сортировки по обычной колонке (число, строка, дата, uuid) на собесе называйте B-tree. Отдельно слово `USING btree` пишут, только если хотят быть явными. Без `USING` будет он же.

## GIN под JSONB

GIN (Generalized Inverted Index) — инвертированный индекс. Он сопоставляет отдельные элементы внутри значения со списком строк, где эти элементы встречаются. Для JSONB, массивов и полнотекстового поиска берут его. На этом собесе из всего списка нужен JSONB.

Оператор `@>` значит «левый JSONB содержит правый».

```sql
CREATE INDEX products_attrs_gin ON products USING gin (attrs);

SELECT sku, title
FROM products
WHERE attrs @> '{"color": "red"}';
```

Ожидается чайник `SKU-1`.

Тот же поиск по колонке типа `json` напрямую не работает: оператор `@>` относится к `jsonb`. Текст из `json` сначала приводят:

```sql
SELECT sku
FROM products
WHERE legacy_payload::jsonb @> '{"color": "red"}';
```

Такой каст индекс по `attrs` не использует. Поэтому колонку, по которой ищут, сразу объявляют `jsonb` и индексируют GIN, а не хранят `json` «на всякий случай».

B-tree по всей колонке `jsonb` для `@>` не подходит: B-tree сравнивает значение целиком, а GIN умеет залезть в ключи внутри документа.

Фраза на собес: «Обычный фильтр, диапазон и сортировка — B-tree. Поиск ключа внутри JSONB — GIN и оператор `@>`».

## Ответы на пять запросов

1.

```sql
SELECT title, price
FROM products
WHERE price > 300
ORDER BY price DESC;
```

Чайник, затем кружка. Тарелка 120 не входит.

2.

```sql
SELECT c.email, o.status, o.total_amount
FROM orders AS o
JOIN customers AS c ON c.id = o.customer_id;
```

3.

```sql
SELECT c.email, count(o.id) AS orders_count
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.id
GROUP BY c.email
ORDER BY c.email;
```

`count(o.id)`, не `count(*)`: у клиента без заказа строка после `LEFT JOIN` одна, и `count(*)` посчитал бы её заказом. `count(o.id)` пропускает `NULL`.

4.

```sql
SELECT status, sum(total_amount) AS amount
FROM orders
GROUP BY status
HAVING sum(total_amount) > 300;
```

В семе `paid` даёт 2340.50, `cancelled` даёт 350. `new` даёт 120 и отсекается `HAVING`.

5.

```sql
SELECT c.email, p.sku, i.qty, i.price
FROM order_items AS i
JOIN orders AS o ON o.id = i.order_id
JOIN customers AS c ON c.id = o.customer_id
LEFT JOIN products AS p ON p.id = i.product_id;
```

К товару `LEFT JOIN`: `product_id` может стать `NULL` после `ON DELETE SET NULL`. К заказу и клиенту обычный `JOIN`: без них позиции в нашей схеме не бывает.
