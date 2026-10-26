# Воскресенье, первый блок. Python, 4–5 часов

Смотрите синтаксис глазами JavaScript. К концу блока три скрипта сами пишут в субботний Postgres. Готовые файлы — в `практика/решения`. Открывайте их после своей попытки.

Сейчас команда `python` на машине не запускает интерпретатор: в PowerShell отвечает заглушка магазина Windows. Поставьте Python 3 с [python.org](https://www.python.org/downloads/windows/) и на первом экране установщика отметьте Add python.exe to PATH. Закройте и заново откройте PowerShell. Если `python --version` всё ещё не показывает номер версии, отключите псевдонимы: Параметры → Приложения → Дополнительные параметры приложения → Псевдонимы выполнения приложений → выключить `python.exe` и `python3.exe`.

Окружение ставьте в папке `практика`. Система у вас Windows, поэтому активация не `source .venv/bin/activate`. Так делают в bash. В PowerShell:

```powershell
cd "C:\Users\User\interview-preparation\практика"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install psycopg2-binary requests
python -m pip freeze > requirements.txt
```

Если политика запуска не пускает `Activate.ps1`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

Пакет называется `psycopg2-binary`, импорт всё равно `import psycopg2`. Обычный `psycopg2` на Windows часто не собирается, потому что ему нужен компилятор. Модуль в коде один и тот же.

Проверка, что интерпретатор из окружения:

```powershell
python -c "import psycopg2, requests; print('ok')"
```

Дальше часы примерно такие. Час 1 — синтаксис. Час 2 — типы и коллекции. Час 3 — функции, файлы, модули. Час 4 — json, csv, requests, соединение с базой. Остаток — три скрипта руками.

## Час 1. Синтаксис напротив JS

Блок задаёт отступ, обычно четыре пробела. Фигурных скобок нет. После `if`, `for`, `while`, `def`, `class`, `try` стоит двоеточие. Точку с запятой не ставят.

```python
def is_paid(order):
    if order["status"] == "paid":
        return True
    return False
```

| JavaScript | Python |
| --- | --- |
| `null`, `undefined` | `None`. Отдельного `undefined` нет |
| `true`, `false` | `True`, `False` |
| `&&`, `\|\|`, `!` | `and`, `or`, `not` |
| `===` | `==` для значений. `is` оставляют для `None`: `x is None` |
| `n++` | `n += 1` |
| `` `Привет, ${name}` `` | `f"Привет, {name}"` |
| `// комментарий` | `# комментарий` |
| `console.log(x)` | `print(x)` |
| `arr.length` | `len(arr)` |
| `else if` | `elif` |

`==` сравнивает значение. `is` спрашивает, тот же ли это объект. На собеседовании `None` проверяют через `is`. Числа и строки сравнивают через `==`.

f-строка подставляет выражение в фигурных скобках:

```python
name = "Анна"
print(f"Привет, {name}")
```

Кавычки строк одинарные или двойные, оба варианта нормальны. Для текста JSON с двойными кавычками внутри удобнее внешние одинарные: `'{"ok": true}'`.

Словарь — не объект JS. Ключ читают скобками: `order["status"]`. Точка у словаря не достаёт ключ. `order.get("comment")` вернёт `None`, если ключа нет. `order["comment"]` в этом случае бросит `KeyError`.

## Час 2. Типы и структуры

Базовые: `int`, `float`, `str`, `bool`, `None`.

`float` здесь такой же двоичный, как `number` в JS. Проверка:

```python
print(0.1 + 0.2)
```

Увидите `0.30000000000000004`. Для денег берите `Decimal` из модуля `decimal`, а в базе — `numeric`. Это прямое продолжение субботы.

```python
from decimal import Decimal
price = Decimal("1990.50")
```

Строку в `Decimal` передают текстом `"1990.50"`, не через `float`.

`list` — массив. Порядок есть, дубли можно.

```python
nums = [10, 20, 30, 40]
nums.append(50)
print(nums[0])
print(nums[-1])
print(nums[1:3])
```

`nums[1:3]` — элементы с индекса 1 до 3, правый конец не входит: `20` и `30`. `nums[-1]` — последний. Это срез, исходный список на месте.

`dict` — объект в смысле «набор пар». Ключи обычно строки.

```python
order = {"id": 10, "status": "new"}
order.get("status")
order["note"] = "позвонить"
for key, value in order.items():
    print(key, value)
list(order.keys())
```

`tuple` — неизменяемая последовательность: `(10, "paid")`. После создания элемент по индексу не заменяют. Строка из базы часто приезжает кортежем.

`set` — уникальные элементы:

```python
unique = {1, 2, 2, 3}
```

В `unique` останутся 1, 2 и 3. Порядок набором не обещают.

List comprehension — ваш `map` и `filter` одним выражением:

```javascript
arr.filter((x) => x > 0).map((x) => x * 2)
```

```python
[x * 2 for x in arr if x > 0]
```

Слева что положить, потом `for`, потом необязательный `if`.

## Час 3. Функции, файлы, модули

```python
def full_name(first, last, middle=""):
    if middle:
        return f"{last} {first} {middle}"
    return f"{last} {first}"

full_name("Анна", "Иванова")
full_name("Анна", "Иванова", middle="Сергеевна")
```

Аргумент с `middle=""` можно не передавать. Именованный вызов ставит значение на конкретное имя, порядок тогда не важен.

Значение по умолчанию считается один раз, в момент объявления функции. Список в этом месте общий для всех вызовов, так не делают:

```python
def add(item, items=[]):
    items.append(item)
    return items
```

Два вызова `add(1)` и `add(2)` вернут `[1]`, потом `[1, 2]`. Нужно так:

```python
def add(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

Ошибки:

```python
try:
    qty = int("много")
except ValueError:
    qty = 0
```

Это ваш `try / catch`. Ловят конкретный класс, не голый `except`. Выбросить ошибку: `raise ValueError("qty must be positive")`.

Файл:

```python
with open("products.csv", encoding="utf-8", newline="") as handle:
    text = handle.read()
```

`with` сам закроет файл на выходе из блока, в том числе если внутри будет ошибка. `encoding="utf-8"` нужен для кириллицы в Windows. `newline=""` нужен модулю `csv`, чтобы он сам разобрал концы строк.

Свой модуль. Рядом положите `money.py`:

```python
from decimal import Decimal

def parse_price(raw):
    return Decimal(raw)
```

Из другого файла в той же папке:

```python
from money import parse_price
```

Запускайте скрипт из этой папки. `import` ищет модуль рядом с запуском и в путях интерпретатора.

## Час 4. Данные и Postgres

JSON:

```python
import json

raw = '{"ok": true, "name": null}'
data = json.loads(raw)
text = json.dumps(data, ensure_ascii=False)
```

`data["ok"]` станет `True`, `data["name"]` станет `None`. `ensure_ascii=False` оставляет кириллицу читаемой.

CSV:

```python
import csv

with open("products.csv", encoding="utf-8", newline="") as handle:
    for row in csv.DictReader(handle):
        print(row["sku"], row["price"])
```

`DictReader` берёт первую строку файла как имена ключей. Каждая следующая строка — словарь. Значения из CSV всегда строки. `price` надо провести через `Decimal`, `stock` через `int`, прежде чем класть в базу.

HTTP:

```python
import requests

response = requests.get(
    "https://jsonplaceholder.typicode.com/users",
    timeout=15,
)
response.raise_for_status()
users = response.json()
print(users[0]["email"])
```

`raise_for_status()` превратит 4xx и 5xx в исключение. `response.json()` уже разбирает тело. `timeout` ставьте всегда: без него запрос может висеть.

Соединение. Файл `db.py` в папке `практика`:

```python
import psycopg2

def get_conn():
    return psycopg2.connect(
        host="localhost",
        port=5432,
        dbname="postgres",
        user="postgres",
        password="pass",
    )
```

Пароль учебный, тот же, что в `docker run`. В боевой репозиторий так не кладут.

Запрос и параметры:

```python
from db import get_conn

conn = get_conn()
try:
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id, email FROM customers WHERE is_active = %s",
            (True,),
        )
        for row in cur.fetchall():
            print(row)
    conn.commit()
finally:
    conn.close()
```

`%s` — место параметра у psycopg2, не приглашение подставить строку через `%` или f-строку. Значения передают вторым аргументом, кортежем. Запятая в `(True,)` обязательна: без неё скобки не делают кортеж.

Так нельзя, это SQL-инъекция. В строку попадёт всё, что прислали, включая кусок запроса:

```python
cur.execute("SELECT id FROM customers WHERE email = '" + email + "'")
```

Нужно так:

```python
cur.execute(
    "SELECT id FROM customers WHERE email = %s",
    (email,),
)
```

`fetchall()` возвращает список кортежей. Имена колонок лежат в `cur.description`. `commit()` фиксирует `INSERT` и `UPDATE`. Без него при закрытии соединения незафиксированная запись откатится. `SELECT` тоже можно коммитить, ему это не вредит.

`with conn.cursor()` закрывает курсор. Соединение закройте сами в `finally`, либо вторым `with` вокруг соединения, если хотите. Явный `close` в трёх скриптах понятнее.

## Три скрипта, которые надо написать самому

Postgres из субботы запущен, таблицы созданы. Окружение активировано, вы в папке `практика`.

1. `load_products.py` читает `products.csv` и вставляет `sku`, `title`, `price`, `stock` в `products`. Повторный запуск не падает на уже существующем артикуле: `ON CONFLICT (sku) DO NOTHING`. Цену ведёте через `Decimal`.
2. `load_users.py` делает GET на `https://jsonplaceholder.typicode.com/users` и кладёт `name`, `email`, `phone` в `customers` (`full_name`, `email`, `phone`). Конфликт по email глотаете так же, через `ON CONFLICT (email) DO NOTHING`.
3. `export_orders.py` выполняет `SELECT` с соединением заказов, клиентов, позиций и товаров и печатает JSON. Товары соединяйте `LEFT JOIN`: `product_id` может быть `NULL`.

`Decimal` и `datetime` сами в `json.dumps` не уходят. Передайте `default`: для `Decimal` верните `str(value)`, для даты и времени — `value.isoformat()`.

Каркас соединения во всех трёх один: `get_conn`, `cursor`, `execute` с `%s`, `commit` на записи, `close`.

Проверка:

```powershell
python load_products.py
python load_users.py
python export_orders.py
```

После первого скрипта в базе есть `SKU-10`, `SKU-11`, `SKU-12`. `SKU-1` из CSV уже был в seed и пропускается. После второго у клиентов появляются адреса с jsonplaceholder. Третий печатает массив объектов, в объектах есть email и артикул.

Если третий скрипт напечатал `[]`, в `orders` и `order_items` нет строк. Вернитесь к `seed.sql`.

## Мелочь, которую стоит проговорить

- Отступ сломан — `IndentationError`, программа не запустится.
- `true` вместо `True` — `NameError`.
- Ключ через точку у словаря — `AttributeError` или тихий промах, если так назван метод.
- Забыли запятую в кортеже из одного элемента — в запрос уедет не то.
- Склеили SQL строкой — на собесе это неправильный ответ, даже если пример «просто учебный».

## Ответы на короткие упражнения

Перепишите, потом смотрите.

Функция суммы оплаченных, аналог `filter` + `reduce`:

```python
def paid_total(orders):
    return sum(order["total"] for order in orders if order["status"] == "paid")
```

Достать email, не роняя программу, если ключа нет:

```python
email = user.get("email")
```

Чётные числа:

```python
[x for x in nums if x % 2 == 0]
```

Ловушка `def add(item, items=[])` — список по умолчанию один на все вызовы, второе добавление увидит первое.
