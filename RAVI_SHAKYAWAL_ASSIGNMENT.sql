
-- Q1: What is the count of purchases per month (excluding refunded purchases)? 
SELECT
    date_trunc('month', purchase_time) AS purchase_month,
    COUNT(*) AS purchase_count
FROM transactions
WHERE refund_time IS NULL              -- exclude refunded purchases
GROUP BY date_trunc('month', purchase_time)
ORDER BY purchase_month;





-- Q2: How many stores receive at least 5 orders/transactions in October 2020? 
WITH store_counts AS (
    SELECT
        store_id,
        COUNT(*) AS num_transactions
    FROM transactions
    WHERE purchase_time >= DATE '2020-10-01'
      AND purchase_time <  DATE '2020-11-01'
    GROUP BY store_id
)
SELECT COUNT(*) AS num_stores_with_5_plus_orders
FROM store_counts
WHERE num_transactions >= 5;







-- Q3: For each store, what is the shortest interval (in min) from purchase to refund time? 
SELECT
    store_id,
    MIN(EXTRACT(EPOCH FROM (refund_time - purchase_time)) / 60.0)
        AS min_minutes_to_refund
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id
ORDER BY store_id;




-- Q4: What is the gross_transaction_value of every store’s first order? 
WITH ranked_orders AS (
    SELECT
        store_id,
        purchase_time,
        gross_transaction_value,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions
)
SELECT
    store_id,
    purchase_time AS first_order_time,
    gross_transaction_value AS first_order_gross_value
FROM ranked_orders
WHERE rn = 1
ORDER BY store_id;







-- Q5: What is the most popular item name that buyers order on their first purchase?


WITH first_purchase AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions t
    -- If we *only* want non-refunded first purchases, uncomment:
    -- WHERE refund_time IS NULL
),
first_purchase_items AS (
    SELECT
        fp.buyer_id,
        fp.store_id,
        fp.item_id,
        i.item_name
    FROM first_purchase fp
    JOIN items i
      ON fp.store_id = i.store_id
     AND fp.item_id  = i.item_id
    WHERE fp.rn = 1
)
SELECT
    item_name,
    COUNT(*) AS num_buyers
FROM first_purchase_items
GROUP BY item_name
ORDER BY num_buyers DESC, item_name
LIMIT 1;     






-- Q6: Create a flag in the transaction items table indicating whether the refund can be processed or 
  --    not. The condition for a refund to be processed is that it has to happen within 72 of Purchase 
    --  time. 
    --  Expected Output: Only 1 of the three refunds would be processed in this case 
-- Assuming "72" means 72 hours.

SELECT
    t.*,
    CASE
        WHEN refund_time IS NOT NULL
         AND refund_time <= purchase_time + INTERVAL '72 hours'
        THEN 1
        ELSE 0
    END AS refund_processable_flag
FROM transactions t;



SELECT
    t.*,
    i.item_category,
    i.item_name,
    CASE
        WHEN t.refund_time IS NOT NULL
         AND t.refund_time <= t.purchase_time + INTERVAL '72 hours'
        THEN 1
        ELSE 0
    END AS refund_processable_flag
FROM transactions t
JOIN items i
  ON t.store_id = i.store_id
 AND t.item_id  = i.item_id;


-- Q7: Create a rank by buyer_id column in the transaction items table and filter for only the second
--purchase per buyer. (Ignore refunds here)
--Expected Output: Only the second purchase of buyer_id 3 should the output


WITH ranked_purchases AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS purchase_rank
    FROM transactions t
    WHERE refund_time IS NULL        
)
SELECT *
FROM ranked_purchases
WHERE purchase_rank = 2;




-- Q8:  How will you find the second transaction time per buyer (don’t use min/max; assume there
--were more transactions per buyer in the table)
--Expected Output: Only the second purchase of buyer_id along with a timestamp

WITH ranked_transactions AS (
    SELECT
        buyer_id,
        purchase_time,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions
)
SELECT
    buyer_id,
    purchase_time AS second_transaction_time
FROM ranked_transactions
WHERE rn = 2
ORDER BY buyer_id;