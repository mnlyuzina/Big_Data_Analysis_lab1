SET datestyle = 'ISO, MDY';

DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_seller CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_store CASCADE;
DROP TABLE IF EXISTS dim_supplier CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS raw_sales_data CASCADE;

-- Сырая таблица
CREATE TABLE raw_sales_data (
    id INT,
    customer_first_name VARCHAR,
    customer_last_name VARCHAR,
    customer_age INT,
    customer_email VARCHAR,
    customer_country VARCHAR,
    customer_postal_code VARCHAR,
    customer_pet_type VARCHAR,
    customer_pet_name VARCHAR,
    customer_pet_breed VARCHAR,
    seller_first_name VARCHAR,
    seller_last_name VARCHAR,
    seller_email VARCHAR,
    seller_country VARCHAR,
    seller_postal_code VARCHAR,
    product_name VARCHAR,
    product_category VARCHAR,
    product_price DECIMAL,
    product_quantity INT,
    sale_date DATE,
    sale_customer_id INT,
    sale_seller_id INT,
    sale_product_id INT,
    sale_quantity INT,
    sale_total_price DECIMAL,
    store_name VARCHAR,
    store_location VARCHAR,
    store_city VARCHAR,
    store_state VARCHAR,
    store_country VARCHAR,
    store_phone VARCHAR,
    store_email VARCHAR,
    pet_category VARCHAR,
    product_weight DECIMAL,
    product_color VARCHAR,
    product_size VARCHAR,
    product_brand VARCHAR,
    product_material VARCHAR,
    product_description TEXT,
    product_rating DECIMAL,
    product_reviews INT,
    product_release_date DATE,
    product_expiry_date DATE,
    supplier_name VARCHAR,
    supplier_contact VARCHAR,
    supplier_email VARCHAR,
    supplier_phone VARCHAR,
    supplier_address VARCHAR,
    supplier_city VARCHAR,
    supplier_country VARCHAR
);

COPY raw_sales_data FROM '/attachments/MOCK_DATA_1.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_3.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_4.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_5.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_6.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_7.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_8.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_9.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COPY raw_sales_data FROM '/attachments/MOCK_DATA_10.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- Таблицы измерений


CREATE TABLE dim_supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR,
    supplier_contact VARCHAR,
    supplier_email VARCHAR,
    supplier_phone VARCHAR,
    supplier_address VARCHAR,
    supplier_city VARCHAR,
    supplier_country VARCHAR,
    UNIQUE (supplier_name, supplier_contact, supplier_email)
);

INSERT INTO dim_supplier (supplier_name, supplier_contact, supplier_email, supplier_phone, supplier_address, supplier_city, supplier_country)
SELECT DISTINCT supplier_name, supplier_contact, supplier_email, supplier_phone, supplier_address, supplier_city, supplier_country
FROM raw_sales_data
WHERE supplier_name IS NOT NULL
ON CONFLICT DO NOTHING;


CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR,
    last_name VARCHAR,
    age INT,
    email VARCHAR,
    country VARCHAR,
    postal_code VARCHAR,
    pet_type VARCHAR,
    pet_name VARCHAR,
    pet_breed VARCHAR
);

INSERT INTO dim_customer (customer_id, first_name, last_name, age, email, country, postal_code, pet_type, pet_name, pet_breed)
SELECT DISTINCT ON (sale_customer_id) 
    sale_customer_id, 
    customer_first_name, 
    customer_last_name, 
    customer_age, 
    customer_email, 
    customer_country, 
    customer_postal_code, 
    customer_pet_type, 
    customer_pet_name, 
    customer_pet_breed
FROM raw_sales_data
WHERE sale_customer_id IS NOT NULL
ORDER BY sale_customer_id;


CREATE TABLE dim_seller (
    seller_id INT PRIMARY KEY,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    country VARCHAR,
    postal_code VARCHAR
);

INSERT INTO dim_seller (seller_id, first_name, last_name, email, country, postal_code)
SELECT DISTINCT ON (sale_seller_id)
    sale_seller_id,
    seller_first_name,
    seller_last_name,
    seller_email,
    seller_country,
    seller_postal_code
FROM raw_sales_data
WHERE sale_seller_id IS NOT NULL
ORDER BY sale_seller_id;


CREATE TABLE dim_store (
    store_id SERIAL PRIMARY KEY,
    store_name VARCHAR,
    store_location VARCHAR,
    store_city VARCHAR,
    store_state VARCHAR,
    store_country VARCHAR,
    store_phone VARCHAR,
    store_email VARCHAR,
    UNIQUE (store_name, store_location, store_city, store_state, store_country)
);

INSERT INTO dim_store (store_name, store_location, store_city, store_state, store_country, store_phone, store_email)
SELECT DISTINCT 
    COALESCE(store_name, 'Unknown'),
    COALESCE(store_location, 'Unknown'),
    COALESCE(store_city, 'Unknown'),
    COALESCE(store_state, 'Unknown'),
    COALESCE(store_country, 'Unknown'),
    store_phone,
    store_email
FROM raw_sales_data
ON CONFLICT DO NOTHING;


CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE,
    year INT,
    quarter INT,
    month INT,
    day INT,
    day_of_week INT,
    day_name VARCHAR,
    month_name VARCHAR
);

INSERT INTO dim_date (date_id, full_date, year, quarter, month, day, day_of_week, day_name, month_name)
SELECT DISTINCT
    (EXTRACT(YEAR FROM sale_date) * 10000 + EXTRACT(MONTH FROM sale_date) * 100 + EXTRACT(DAY FROM sale_date))::INT,
    sale_date,
    EXTRACT(YEAR FROM sale_date)::INT,
    EXTRACT(QUARTER FROM sale_date)::INT,
    EXTRACT(MONTH FROM sale_date)::INT,
    EXTRACT(DAY FROM sale_date)::INT,
    EXTRACT(DOW FROM sale_date)::INT,
    TO_CHAR(sale_date, 'Day'),
    TO_CHAR(sale_date, 'Month')
FROM raw_sales_data
WHERE sale_date IS NOT NULL
ON CONFLICT (date_id) DO NOTHING;


CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR,
    product_category VARCHAR,
    product_price DECIMAL,
    product_quantity_on_hand INT,
    product_weight DECIMAL,
    product_color VARCHAR,
    product_size VARCHAR,
    product_brand VARCHAR,
    product_material VARCHAR,
    product_description TEXT,
    product_rating DECIMAL,
    product_reviews INT,
    product_release_date DATE,
    product_expiry_date DATE,
    pet_category VARCHAR,
    supplier_id INT REFERENCES dim_supplier(supplier_id)
);

INSERT INTO dim_product (product_id, product_name, product_category, product_price, product_quantity_on_hand, product_weight, product_color, product_size, product_brand, product_material, product_description, product_rating, product_reviews, product_release_date, product_expiry_date, pet_category, supplier_id)
SELECT DISTINCT ON (sale_product_id)
    sale_product_id,
    product_name,
    product_category,
    product_price,
    product_quantity,
    product_weight,
    product_color,
    product_size,
    product_brand,
    product_material,
    product_description,
    product_rating,
    product_reviews,
    product_release_date,
    product_expiry_date,
    pet_category,
    s.supplier_id
FROM raw_sales_data r
LEFT JOIN dim_supplier s ON r.supplier_name = s.supplier_name AND r.supplier_contact = s.supplier_contact AND r.supplier_email = s.supplier_email
WHERE sale_product_id IS NOT NULL
ORDER BY sale_product_id;


-- Таблица фактов (с автоинкрементом)

CREATE TABLE fact_sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES dim_customer(customer_id),
    seller_id INT REFERENCES dim_seller(seller_id),
    product_id INT REFERENCES dim_product(product_id),
    store_id INT REFERENCES dim_store(store_id),
    sale_date_id INT REFERENCES dim_date(date_id),
    sale_quantity INT,
    sale_total_price DECIMAL
);

INSERT INTO fact_sales (customer_id, seller_id, product_id, store_id, sale_date_id, sale_quantity, sale_total_price)
SELECT
    r.sale_customer_id,
    r.sale_seller_id,
    r.sale_product_id,
    st.store_id,
    d.date_id,
    r.sale_quantity,
    r.sale_total_price
FROM raw_sales_data r
JOIN dim_store st ON COALESCE(r.store_name, 'Unknown') = st.store_name 
                 AND COALESCE(r.store_location, 'Unknown') = st.store_location
                 AND COALESCE(r.store_city, 'Unknown') = st.store_city
                 AND COALESCE(r.store_state, 'Unknown') = st.store_state
                 AND COALESCE(r.store_country, 'Unknown') = st.store_country
JOIN dim_date d ON (EXTRACT(YEAR FROM r.sale_date) * 10000 + EXTRACT(MONTH FROM r.sale_date) * 100 + EXTRACT(DAY FROM r.sale_date))::INT = d.date_id;


CREATE INDEX idx_fact_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_seller ON fact_sales(seller_id);
CREATE INDEX idx_fact_product ON fact_sales(product_id);
CREATE INDEX idx_fact_store ON fact_sales(store_id);
CREATE INDEX idx_fact_date ON fact_sales(sale_date_id);