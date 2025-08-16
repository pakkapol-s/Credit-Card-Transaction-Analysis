-- 1. What is the average, maximum, and minimum transaction amount for fraudulent versus non-fraudulent transactions?

SELECT
  fraud,
  ROUND(CAST(AVG(amt) AS NUMERIC), 2) AS avg_amt,
  MAX(amt) AS max_amt,
  MIN(amt) AS min_amt
FROM transactions
GROUP BY fraud ;

-- "fraud","avg_amt","max_amt","min_amt"
-- 0,"54.27",304.6,0
-- 1,"79.57",290.84,0.01

-- 2. What are the top 10 most common merchant category codes (MCCs) for all transactions?

SELECT
    TP.mcc,
    COUNT(T.transaction_id) AS num_of_transactions
FROM transactions AS T
JOIN terminal_profiles AS TP
ON T.terminal_id = TP.terminal_id
GROUP BY TP.mcc
ORDER BY num_of_transactions DESC
LIMIT 10 ;

-- "mcc","num_of_transactions"
-- 5814,"528130"
-- 5813,"316188"
-- 5812,"307309"
-- 4011,"109244"
-- 3501,"72095"
-- 5601,"60485"
-- 763,"56144"
-- 780,"43180"
-- 742,"41869"
-- 5661,"41168"

-- 3. Are there customers with an unusually high number of transactions compared to the average?

WITH customer_transaction_count AS (
    SELECT
        customer_id,
        COUNT(transaction_id) AS num_transactions
    FROM
        transactions
    GROUP BY
        customer_id
)
SELECT
    customer_id,
    num_transactions
FROM
    customer_transaction_count
WHERE
    num_transactions > (SELECT AVG(num_transactions) FROM customer_transaction_count)
ORDER BY
    num_transactions DESC;

-- 5. Do fraudulent transactions occur more frequently during specific hours of the day or days of the week?

-- by hour

SELECT
    EXTRACT(HOUR FROM post_ts) AS transaction_hour,
    COUNT(transaction_id) AS num_fraudulent_transactions
FROM
    transactions
WHERE
    fraud = 1
GROUP BY
    transaction_hour
ORDER BY
    num_fraudulent_transactions DESC;

-- "transaction_hour","num_fraudulent_transactions"
-- "23","4520"
-- "22","4024"
-- "21","3801"
-- "20","3778"
-- "19","3537"
-- "18","3388"
-- "17","3250"
-- "16","3205"
-- "15","3117"
-- "14","2827"
-- "13","2699"
-- "12","2475"
-- "11","2371"
-- "10","2094"
-- "9","1840"
-- "8","1590"
-- "7","1295"
-- "6","1018"
-- "5","828"
-- "4","657"
-- "3","469"
-- "2","361"
-- "1","262"
-- "0","163"

-- by day

SELECT
    CASE
        WHEN EXTRACT(DOW FROM post_ts) = 0 THEN 'Sunday'
        WHEN EXTRACT(DOW FROM post_ts) = 1 THEN 'Monday'
        WHEN EXTRACT(DOW FROM post_ts) = 2 THEN 'Tuesday'
        WHEN EXTRACT(DOW FROM post_ts) = 3 THEN 'Wednesday'
        WHEN EXTRACT(DOW FROM post_ts) = 4 THEN 'Thursday'
        WHEN EXTRACT(DOW FROM post_ts) = 5 THEN 'Friday'
        WHEN EXTRACT(DOW FROM post_ts) = 6 THEN 'Saturday'
    END AS day_of_week,
    COUNT(transaction_id) AS num_fraudulent_transactions
FROM
    transactions
WHERE
    fraud = 1
GROUP BY
    day_of_week
ORDER BY
    num_fraudulent_transactions DESC;

-- "day_of_week","num_fraudulent_transactions"
-- "Sunday","7875"
-- "Thursday","7826"
-- "Wednesday","7724"
-- "Tuesday","7693"
-- "Friday","7626"
-- "Saturday","7501"
-- "Monday","7324"

-- Fraud-Specific Analysis

-- 6. Which terminals have the highest percentage of fraudulent transactions?

SELECT
    terminal_id,
    COUNT(transaction_id) AS total_transactions,
    SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END) AS fraudulent_transactions,
    ROUND(
        ( (SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END)::FLOAT / COUNT(transaction_id)::FLOAT) * 100 )::NUMERIC, 2
    ) AS fraud_percentage
FROM
    transactions
GROUP BY
    terminal_id
HAVING
    COUNT(transaction_id) >= 10
ORDER BY
    fraud_percentage DESC
LIMIT 10;

"terminal_id","total_transactions","fraudulent_transactions","fraud_percentage"
"T001043","18322","668","3.65"
"T001004","16556","585","3.53"
"T001052","13512","476","3.52"
"T001016","15329","525","3.42"
"T001010","14317","488","3.41"
"T001087","18290","616","3.37"
"T001012","12931","434","3.36"
"T001040","23968","797","3.33"
"T001070","25648","854","3.33"
"T001056","13553","450","3.32"

-- 7. Identify customers who have at least one fraudulent transaction and have a higher-than-average number of available terminals.

WITH AvgTerminals AS (
    SELECT
        AVG(nb_terminals) AS avg_num_terminals
    FROM
        customer_profiles
)
SELECT
    CP.customer_id,
    COUNT(T.transaction_id) AS fraud_transactions,
    CP.nb_terminals
FROM
    customer_profiles AS CP
JOIN
    transactions AS T
ON
    CP.customer_id = T.customer_id
WHERE
    T.fraud = 1
GROUP BY
    CP.customer_id,
    CP.nb_terminals
HAVING
    COUNT(T.transaction_id) > 1 AND CP.nb_terminals > (
        SELECT avg_num_terminals FROM AvgTerminals
    )
ORDER BY
    fraud_transactions DESC;