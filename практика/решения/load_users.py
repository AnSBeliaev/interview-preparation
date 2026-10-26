import requests

from db import get_conn


def main():
    response = requests.get(
        "https://jsonplaceholder.typicode.com/users",
        timeout=15,
    )
    response.raise_for_status()
    users = response.json()

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            for user in users:
                cur.execute(
                    """
                    INSERT INTO customers (email, full_name, phone)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (email) DO NOTHING
                    """,
                    (user["email"], user["name"], user["phone"]),
                )
        conn.commit()
    finally:
        conn.close()


if __name__ == "__main__":
    main()
