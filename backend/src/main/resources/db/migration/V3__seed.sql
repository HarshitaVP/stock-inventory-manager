-- V3__seed.sql  ·  Demo data (SRS §5.3)
-- Put this file in: backend/src/main/resources/db/migration/V3__seed.sql
--
-- Creates: 5 areas, 50 stores, ~200 products in 6 categories, a stock row for every
-- product in every store (~10,000 rows, some deliberately low), and a few
-- authorisation rules that match the SRS acceptance criteria.
--
-- Users are NOT created here: passwords must never be stored in Git, even hashed.
-- They are created at startup by a CommandLineRunner (built in M1) that reads
-- the passwords from environment variables.

-- Same "random" numbers every time, so every database gets identical demo data.
SELECT setseed(0.42);

-- ---------- Areas ----------
INSERT INTO area (code, name) VALUES
    ('NORTH',   'North Bengaluru'),
    ('SOUTH',   'South Bengaluru'),
    ('EAST',    'East Bengaluru'),
    ('WEST',    'West Bengaluru'),
    ('CENTRAL', 'Central Bengaluru');

-- ---------- Stores (10 per area) ----------
INSERT INTO store (code, name, area_id, active)
SELECT v.code, v.name, a.id, v.active
FROM (VALUES
    ('S003','Hebbal','NORTH',true), ('S004','Yelahanka','NORTH',true), ('S005','Sahakar Nagar','NORTH',true),
    ('S006','RT Nagar','NORTH',true), ('S007','Thanisandra','NORTH',true), ('S008','Jakkur','NORTH',false),
    ('S041','Hennur','NORTH',true), ('S042','Kalyan Nagar','NORTH',true), ('S043','Banaswadi','NORTH',true),
    ('S044','Vidyaranyapura','NORTH',true),
    ('S001','Koramangala','SOUTH',true), ('S002','Jayanagar','SOUTH',true), ('S009','JP Nagar','SOUTH',true),
    ('S010','BTM Layout','SOUTH',true), ('S045','HSR Layout','SOUTH',true), ('S046','Banashankari','SOUTH',true),
    ('S047','Basavanagudi','SOUTH',true), ('S048','Electronic City','SOUTH',true),
    ('S049','Bannerghatta Road','SOUTH',true), ('S050','Bommanahalli','SOUTH',true),
    ('S011','Indiranagar','EAST',true), ('S012','HAL','EAST',true), ('S013','Marathahalli','EAST',true),
    ('S014','Whitefield','EAST',true), ('S015','KR Puram','EAST',true), ('S016','Brookefield','EAST',true),
    ('S017','Bellandur','EAST',true), ('S018','Domlur','EAST',true), ('S019','CV Raman Nagar','EAST',true),
    ('S020','Kadugodi','EAST',true),
    ('S021','Rajajinagar','WEST',true), ('S022','Malleshwaram','WEST',true), ('S023','Vijayanagar','WEST',true),
    ('S024','Basaveshwaranagar','WEST',true), ('S025','Yeshwanthpur','WEST',true), ('S026','Peenya','WEST',true),
    ('S027','Nagarbhavi','WEST',true), ('S028','Kengeri','WEST',true), ('S029','RR Nagar','WEST',true),
    ('S030','Mahalakshmi Layout','WEST',true),
    ('S031','MG Road','CENTRAL',true), ('S032','Brigade Road','CENTRAL',true), ('S033','Shivajinagar','CENTRAL',true),
    ('S034','Richmond Town','CENTRAL',true), ('S035','Frazer Town','CENTRAL',true), ('S036','Cubbon Park','CENTRAL',true),
    ('S037','Majestic','CENTRAL',true), ('S038','Chickpet','CENTRAL',true), ('S039','Ulsoor','CENTRAL',true),
    ('S040','Vasanth Nagar','CENTRAL',true)
) AS v(code, name, area, active)
JOIN area a ON a.code = v.area;

-- ---------- Products: named ones first (these appear in the screen designs) ----------
INSERT INTO product (sku, name, category, unit_price, reorder_level, active) VALUES
    ('GRC-1001','Basmati Rice 5 kg','Grocery',649.0000,20,true),
    ('GRC-1002','Toor Dal 1 kg','Grocery',168.5000,30,true),
    ('GRC-1003','Sunflower Oil 1 L','Grocery',155.0000,25,true),
    ('GRC-1004','Whole Wheat Atta 10 kg','Grocery',489.0000,15,true),
    ('BEV-2001','Green Tea 100 bags','Beverages',299.0000,12,true),
    ('BEV-2002','Filter Coffee 500 g','Beverages',345.0000,12,true),
    ('BEV-2003','Orange Juice 1 L','Beverages',120.0000,24,true),
    ('DRY-3001','Almonds 500 g','Dry fruits',520.0000,10,true),
    ('DRY-3002','Cashews 250 g','Dry fruits',310.0000,10,true),
    ('HOM-4001','Dish Wash Liquid 750 ml','Home care',189.0000,18,true),
    ('HOM-4002','Floor Cleaner 1 L','Home care',210.0000,18,true),
    ('HOM-4003','Laundry Powder 4 kg','Home care',560.0000,8,false),
    ('PER-5001','Shampoo 340 ml','Personal care',275.0000,15,true),
    ('PER-5002','Toothpaste 150 g','Personal care',95.5000,40,true),
    ('PER-5003','Bath Soap (pack of 4)','Personal care',180.0000,20,true),
    ('SNK-6001','Salted Peanuts 200 g','Snacks',60.0000,30,true),
    ('SNK-6002','Dark Chocolate 100 g','Snacks',149.5000,10,true),
    ('SNK-6003','Oat Cookies 300 g','Snacks',110.0000,15,true);

-- ---------- Products: fill each category up to 34 items (~200 in total) ----------
INSERT INTO product (sku, name, category, unit_price, reorder_level, active)
SELECT c.prefix || '-' || (c.base + n),
       c.category || ' item ' || lpad(n::text, 2, '0'),
       c.category,
       round((20 + random() * 600)::numeric, 2),
       (5 + floor(random() * 30))::int,
       true
FROM (VALUES
    ('GRC', 1000, 'Grocery'),
    ('BEV', 2000, 'Beverages'),
    ('DRY', 3000, 'Dry fruits'),
    ('HOM', 4000, 'Home care'),
    ('PER', 5000, 'Personal care'),
    ('SNK', 6000, 'Snacks')
) AS c(prefix, base, category)
CROSS JOIN generate_series(1, 34) AS n
ON CONFLICT (sku) DO NOTHING;          -- skips the numbers already used by the named products

-- ---------- Stock: one row per product per store ----------
-- About 7% of rows are deliberately at or below the reorder level, and ~1% are 0,
-- so the "Low stock" and "Out of stock" badges have something to show.
INSERT INTO stock (product_id, store_id, quantity)
SELECT p.id,
       s.id,
       CASE
           WHEN random() < 0.01 THEN 0
           WHEN random() < 0.07 THEN floor(random() * (p.reorder_level + 1))::int
           ELSE (p.reorder_level + 1 + floor(random() * 100))::int
       END
FROM product p
CROSS JOIN store s;

-- ---------- Authorisation rules (match SRS acceptance criteria AC-10 / AC-11) ----------
-- Every product is authorised in NORTH, SOUTH and WEST (CENTRAL and EAST below).
INSERT INTO product_area_auth (product_id, area_id, authorised, updated_by)
SELECT p.id, a.id, true, 'seed'
FROM product p
CROSS JOIN area a
WHERE a.code IN ('NORTH', 'SOUTH', 'WEST');

INSERT INTO product_area_auth (product_id, area_id, authorised, updated_by)
SELECT p.id, a.id, true, 'seed'
FROM product p
JOIN area a ON a.code = 'CENTRAL'
WHERE p.sku <> 'SNK-6002';             -- SNK-6002 has NO rule in CENTRAL → "deny by default" demo

-- In EAST, everything except dry fruits.
INSERT INTO product_area_auth (product_id, area_id, authorised, updated_by)
SELECT p.id, a.id, (p.category <> 'Dry fruits'), 'seed'
FROM product p
JOIN area a ON a.code = 'EAST';

-- Store overrides: Dark Chocolate blocked in S003 Hebbal (its area NORTH allows it),
-- Almonds allowed in S013 Marathahalli (its area EAST blocks dry fruits).
INSERT INTO product_store_auth (product_id, store_id, authorised, updated_by)
SELECT p.id, s.id, false, 'seed'
FROM product p, store s
WHERE p.sku = 'SNK-6002' AND s.code = 'S003';

INSERT INTO product_store_auth (product_id, store_id, authorised, updated_by)
SELECT p.id, s.id, true, 'seed'
FROM product p, store s
WHERE p.sku = 'DRY-3001' AND s.code = 'S013';