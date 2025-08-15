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