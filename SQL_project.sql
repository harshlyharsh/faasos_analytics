CREATE DATABASE FAASOS;
USE FAASOS;

DROP TABLE IF EXISTS driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id, reg_date) 
VALUES 
    (1, '2021-01-01'),
    (2, '2021-01-03'),
    (3, '2021-01-08'),
    (4, '2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

-- Drop the table if it exists
DROP TABLE IF EXISTS driver_order;

-- Create the driver_order table
CREATE TABLE driver_order (
    order_id integer,
    driver_id integer,
    pickup_time datetime,
    distance VARCHAR(10),
    duration VARCHAR(10),
    cancellation VARCHAR(23)
);

-- Insert data into the driver_order table
INSERT INTO driver_order (order_id, driver_id, pickup_time, distance, duration, cancellation) 
VALUES
    (1, 1, '2021-01-01 18:15:34', '20 km', '32 minutes', null),
    (2, 1, '2021-01-01 19:10:54', '20 km', '27 minutes', null),
    (3, 1, '2021-01-03 00:12:37', '13.4 km', '20 mins', null),
    (4, 2, '2021-01-04 13:53:03', '23.4 km', '40 minutes', null),
    (5, 3, '2021-01-08 21:10:57', '10 km', '15 minutes', null),
    (6, 3, null, null, null, 'Cancellation'),
    (7, 2, '2020-01-08 21:30:45', '25 km', '25 mins', null),
    (8, 2, '2020-01-10 00:15:02', '23.4 km', '15 minutes', null),
    (9, 2, null, null, null, 'Customer Cancellation'),
    (10, 1, '2020-01-11 18:50:20', '10 km', '10 minutes', null);



-- Drop the table if it exists
DROP TABLE IF EXISTS customer_orders;

-- Create the customer_orders table
CREATE TABLE customer_orders (
    order_id integer,
    customer_id integer,
    roll_id integer,
    not_include_items VARCHAR(10),
    extra_items_included VARCHAR(10),
    order_date datetime
);

-- Insert data into the customer_orders table
INSERT INTO customer_orders (order_id, customer_id, roll_id, not_include_items, extra_items_included, order_date)
VALUES
    (1, 101, 1, '', '', '2021-01-01 18:05:02'),
    (2, 101, 1, '', '', '2021-01-01 19:00:52'),
    (3, 102, 1, '', '', '2021-01-02 23:51:23'),
    (4, 102, 2, '', 'NaN', '2021-01-02 23:51:23'),
    (4, 103, 1, '4', '', '2021-01-04 13:23:46'),
    (5, 103, 1, '4', '', '2021-01-04 13:23:46'),
    (4, 103, 2, '4', '', '2021-01-04 13:23:46'),
    (5, 104, 1, null, '1', '2021-01-08 21:00:29'),
    (6, 101, 2, null, null, '2021-01-08 21:03:13'),
    (7, 105, 2, null, '1', '2021-01-08 21:20:29'),
    (8, 102, 1, null, null, '2021-01-09 23:54:33'),
    (9, 103, 1, '4', '1,5', '2021-01-10 11:22:59'),
    (10, 104, 1, null, null, '2021-01-11 18:34:49'),
    (10, 104, 1, '2,6', '1,4', '2021-01-11 18:34:49');


select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

-- Roll Metrics

-- How many rolls were ordered?
select count(roll_id) from customer_orders;

-- How many unique customer orders were made?
select count(distinct customer_id) from customer_orders;

-- How many succesful orders were delivered by each driver?
SELECT driver_id, COUNT(DISTINCT order_id)
FROM driver_order
WHERE cancellation NOT IN ('Cancellation', 'Customer Cancellation')
   OR cancellation IS NULL
GROUP BY driver_id;

-- How many each type of roll was delivered?
SELECT r.roll_name, COUNT(co.order_id) AS total_delivered
FROM customer_orders co
JOIN rolls r ON co.roll_id = r.roll_id
WHERE co.order_id NOT IN (
    SELECT order_id
    FROM driver_order
    WHERE cancellation IN ('Cancellation', 'Customer Cancellation')
)
GROUP BY r.roll_name;

-- How many veg and non-veg rolls were ordered by each customer?
SELECT a.*,b.roll_name from
(
select customer_id,roll_id, count(roll_id) cnt
from customer_orders
group by customer_id,roll_id)a inner join rolls b on a.roll_id=b.roll_id;

-- What were the maximum numver of rolls in a single order?
select max(cnt) from
(select order_id,count(roll_id) as cnt from 
(select * from customer_orders where order_id in
(select order_id from driver_order where cancellation is null))a
group by order_id)b; 

-- For each customer, how many delivered rolls had atleast 1 change & how many had no changes
﻿

-- Data Cleaning
WITH temp_customer_orders(order_id, customer_id, roll_id, new_not_include_items, new_extra_items_included, order_date) AS (
    SELECT order_id, customer_id, roll_id,
           CASE WHEN not_include_items IS NULL OR not_include_items = '' THEN '0' ELSE not_include_items END AS new_not_include_items,
           CASE WHEN extra_items_included IS NULL OR extra_items_included = '' OR extra_items_included = 'NaN' THEN '0' ELSE extra_items_included END AS new_extra_items_included,
           order_date
    FROM customer_orders
),
temp_driver_order (order_id, driver_id, pickup_time, distance, duration, new_cancellation) AS (
    SELECT order_id, driver_id, pickup_time, distance, duration,
           CASE WHEN cancellation IN ('Cancellation', 'Customer Cancellation') THEN 0 ELSE 1 END AS new_cancellation
    FROM driver_order
)

SELECT customer_id, chg_no_chg, COUNT(order_id) AS xyz
FROM (
    SELECT *,
           CASE WHEN new_not_include_items = '0' AND new_extra_items_included = '0' THEN 'no change' ELSE 'change' END AS chg_no_chg
    FROM temp_customer_orders
    WHERE order_id IN (SELECT order_id FROM temp_driver_order WHERE new_cancellation != 0)
) a
GROUP BY customer_id, chg_no_chg;

-- How many rolls had both included & excluded items
WITH temp_customer_orders(order_id, customer_id, roll_id, new_not_include_items, new_extra_items_included, order_date) AS (
    SELECT order_id, customer_id, roll_id,
           CASE WHEN not_include_items IS NULL OR not_include_items = '' THEN '0' ELSE not_include_items END AS new_not_include_items,
           CASE WHEN extra_items_included IS NULL OR extra_items_included = '' OR extra_items_included = 'NaN' THEN '0' ELSE extra_items_included END AS new_extra_items_included,
           order_date
    FROM customer_orders
),
temp_driver_order (order_id, driver_id, pickup_time, distance, duration, new_cancellation) AS (
    SELECT order_id, driver_id, pickup_time, distance, duration,
           CASE WHEN cancellation IN ('Cancellation', 'Customer Cancellation') THEN 0 ELSE 1 END AS new_cancellation
    FROM driver_order
)

SELECT  chg_no_chg, COUNT(chg_no_chg) 
FROM (
    SELECT *,
           CASE WHEN new_not_include_items != '0' AND new_extra_items_included != '0' THEN 'both' ELSE 'either' END AS chg_no_chg
    FROM temp_customer_orders
    WHERE order_id IN (SELECT order_id FROM temp_driver_order WHERE new_cancellation != 0)
) a
GROUP BY chg_no_chg;

-- What was the total number of rolls ordered for each hour of the day?
SELECT hours_bucket, COUNT(hours_bucket) 
FROM (
    SELECT *,
    CONCAT(CAST(DATE_FORMAT(order_date, '%H') AS CHAR), '-', CAST((DATE_FORMAT(order_date, '%H') + 1) AS CHAR)) AS hours_bucket
    FROM customer_orders
) a
GROUP BY hours_bucket;

-- What was the number of orders for each day of the week?
SELECT dow, COUNT(DISTINCT order_id)
FROM (
    SELECT *, DATE_FORMAT(order_date, '%W') AS dow
    FROM customer_orders
) a
GROUP BY dow;

-- What was the average in time in minutes it took for driver to arrive at the faasos hq to pickup the order?
SELECT TIMESTAMPDIFF(MINUTE, order_date, pickup_time) AS time_difference_minutes
FROM
(select order_id from
customer_orders a
inner join driver_order b
on a.order_id=b.order_id)a;

SELECT TIMESTAMPDIFF(MINUTE, order_date, pickup_time) AS time_difference_minutes
FROM
(select * from
customer_orders a
inner join driver_order b
on a.order_id=b.order_id)xyz;

-- Is there any relationship between the number of rolls and how long does the order takes to prepare?


-- What is the average distance travelled for each of the customer?
SELECT
    co.customer_id,
    AVG(CAST(REPLACE(d.distance, ' km', '') AS DECIMAL(10, 2))) AS avg_distance
FROM
    customer_orders co
JOIN
    driver_order d ON co.order_id = d.order_id
GROUP BY
    co.customer_id;

-- What was the difference between the longest & shortest delivery time of all the orders?
SELECT
    MAX(a.duration) - MIN(a.duration) AS diff
FROM (
    SELECT
        CAST(
            CASE
                WHEN duration LIKE '%min%' THEN LEFT(duration, CHAR_LENGTH(duration) - 4)
                ELSE duration
            END AS SIGNED
        ) AS duration
    FROM driver_order
    WHERE duration IS NOT NULL
) AS a;

-- What was the average speed for each driver for each delivery?
SELECT
    a.order_id,
    a.driver_id,
    a.distance / a.duration AS speed,
    b.cnt
FROM (
    SELECT
        do.order_id,
        do.driver_id,
        CAST(TRIM(REPLACE(LOWER(do.distance), 'km', '')) AS DECIMAL(4, 2)) AS distance,
        CAST(
            CASE
                WHEN do.duration LIKE '%min%' THEN LEFT(do.duration, LOCATE('m', do.duration) - 1)
                ELSE do.duration
            END AS SIGNED
        ) AS duration
    FROM driver_order do
    WHERE do.distance IS NOT NULL
) AS a
INNER JOIN (
    SELECT order_id, COUNT(roll_id) AS cnt
    FROM customer_orders
    GROUP BY order_id
) AS b ON a.order_id = b.order_id;













