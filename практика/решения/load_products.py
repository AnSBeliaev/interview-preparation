import csv
from decimal import Decimal
from pathlib import Path

from db import get_conn


def csv_path():
    here = Path(__file__).resolve().parent
    near = here / "products.csv"
    if near.exists():
        return near
    return here.parent / "products.csv"


def main():
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            with csv_path().open(encoding="utf-8", newline="") as handle:
                for row in csv.DictReader(handle):
                    cur.execute(
                        """
                        INSERT INTO products (sku, title, price, stock)
                        VALUES (%s, %s, %s, %s)
                        ON CONFLICT (sku) DO NOTHING
                        """,
                        (
                            row["sku"],
                            row["title"],
                            Decimal(row["price"]),
                            int(row["stock"]),
                        ),
                    )
        conn.commit()
    finally:
        conn.close()


if __name__ == "__main__":
    main()
