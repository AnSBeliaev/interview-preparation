import json
from datetime import date, datetime, time
from decimal import Decimal

from db import get_conn


def to_json(value):
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, (datetime, date, time)):
        return value.isoformat()
    raise TypeError(f"не сериализуется: {type(value)}")


def main():
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    c.email,
                    o.id AS order_id,
                    o.status,
                    p.sku,
                    i.qty,
                    i.price
                FROM orders AS o
                JOIN customers AS c ON c.id = o.customer_id
                JOIN order_items AS i ON i.order_id = o.id
                LEFT JOIN products AS p ON p.id = i.product_id
                ORDER BY o.id, i.id
                """
            )
            columns = [desc[0] for desc in cur.description]
            rows = [dict(zip(columns, row)) for row in cur.fetchall()]
    finally:
        conn.close()

    print(json.dumps(rows, ensure_ascii=False, indent=2, default=to_json))


if __name__ == "__main__":
    main()
