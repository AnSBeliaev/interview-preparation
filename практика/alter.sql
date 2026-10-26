SET client_encoding TO 'UTF8';

ALTER TABLE customers ADD COLUMN nickname text;
ALTER TABLE customers DROP COLUMN nickname;
ALTER TABLE customers ALTER COLUMN phone TYPE varchar(80);

ALTER TABLE products
    ADD CONSTRAINT products_stock_nonnegative CHECK (stock >= 0);
