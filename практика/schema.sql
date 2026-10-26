SET client_encoding TO 'UTF8';

CREATE TABLE customers (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email varchar(320) NOT NULL UNIQUE,
    full_name text NOT NULL,
    phone varchar(64),
    country_code char(2) NOT NULL DEFAULT 'RU',
    birth_date date,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE products (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku varchar(64) NOT NULL UNIQUE,
    title text NOT NULL,
    price numeric(12, 2) NOT NULL CHECK (price >= 0),
    weight_kg real,
    rating double precision,
    stock smallint NOT NULL DEFAULT 0,
    attrs jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_payload json,
    external_id uuid NOT NULL DEFAULT gen_random_uuid(),
    CONSTRAINT products_rating_range CHECK (
        rating IS NULL OR (rating >= 0 AND rating <= 5)
    )
);

CREATE TABLE orders (
    id bigserial PRIMARY KEY,
    customer_id bigint NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    status varchar(32) NOT NULL DEFAULT 'new',
    total_amount numeric(12, 2) NOT NULL DEFAULT 0,
    delivery_slot time,
    ordered_at timestamp NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    note text,
    CONSTRAINT orders_status_check CHECK (status IN ('new', 'paid', 'cancelled')),
    CONSTRAINT orders_total_nonnegative CHECK (total_amount >= 0)
);

CREATE TABLE order_items (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id bigint NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    product_id integer REFERENCES products (id) ON DELETE SET NULL,
    qty integer NOT NULL CHECK (qty > 0),
    price numeric(12, 2) NOT NULL CHECK (price >= 0)
);
