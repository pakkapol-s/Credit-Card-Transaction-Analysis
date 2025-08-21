-- 1. What is the average, maximum, and minimum transaction amount for fraudulent versus non-fraudulent transactions?

SELECT
  fraud,
  ROUND(CAST(AVG(amt) AS NUMERIC), 2) AS avg_amt,
  MAX(amt) AS max_amt,
  MIN(amt) AS min_amt
FROM transactions
GROUP BY fraud ;

"fraud","avg_amt","max_amt","min_amt"
0,"54.27",304.6,0
1,"79.57",290.84,0.01

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

"mcc","num_of_transactions"
5814,"528130"
5813,"316188"
5812,"307309"
4011,"109244"
3501,"72095"
5601,"60485"
763,"56144"
780,"43180"
742,"41869"
5661,"41168"

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

-- 4. Do fraudulent transactions occur more frequently during specific hours of the day or days of the week?

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

"transaction_hour","num_fraudulent_transactions"
"23","4520"
"22","4024"
"21","3801"
"20","3778"
"19","3537"
"18","3388"
"17","3250"
"16","3205"
"15","3117"
"14","2827"
"13","2699"
"12","2475"
"11","2371"
"10","2094"
"9","1840"
"8","1590"
"7","1295"
"6","1018"
"5","828"
"4","657"
"3","469"
"2","361"
"1","262"
"0","163"

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

"day_of_week","num_fraudulent_transactions"
"Sunday","7875"
"Thursday","7826"
"Wednesday","7724"
"Tuesday","7693"
"Friday","7626"
"Saturday","7501"
"Monday","7324"

-- Fraud-Specific Analysis

-- 5. Which terminals have the highest percentage of fraudulent transactions?

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

-- 6. Identify customers who have at least one fraudulent transaction and have a higher-than-average number of available terminals.

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

-- 7. Identify "high-value" vs. "low-value" customers based on their average transaction

-- Identifying High-Value Customers

SELECT
  customer_id,
  ROUND(CAST(AVG(amt)AS NUMERIC), 2) AS avg_customer_amt
FROM
  transactions
GROUP BY
  customer_id
HAVING
  AVG(amt) > (SELECT AVG(amt) FROM transactions)
ORDER BY
  avg_customer_amt DESC;

-- Identifying Low-Value Customers

SELECT
  customer_id,
  ROUND(CAST(AVG(amt)AS NUMERIC), 2) AS avg_customer_amt
FROM
  transactions
GROUP BY
  customer_id
HAVING
  AVG(amt) < (SELECT AVG(amt) FROM transactions)
ORDER BY
  avg_customer_amt ASC;

-- 8. What is the average number of days between transactions for each customer?

WITH time_differences AS (
    SELECT
        customer_id,
        (EXTRACT(EPOCH FROM (post_ts - LAG(post_ts, 1) OVER (PARTITION BY customer_id ORDER BY post_ts))) / 86400.0) AS days_between_transactions,
        MAX(fraud) AS has_fraudulent_transaction
    FROM transactions
    GROUP BY customer_id, post_ts, fraud
)
SELECT
    has_fraudulent_transaction,
    AVG(days_between_transactions) AS avg_days_between_transactions
FROM
    time_differences
WHERE
    days_between_transactions IS NOT NULL
GROUP BY
    has_fraudulent_transaction;

"has_fraudulent_transaction","avg_days_between_transactions"
0,"0.504841967953278259243426"
1,"0.218510025599484894783325"

-- 9. What is the distribution of fraudulent transactions across different entry_mode types (e.g., 'Contactless', 'Swipe')?

SELECT entry_mode,
  COUNT(transaction_id) as num_of_transactions
FROM transactions
WHERE fraud = 1
GROUP BY entry_mode

"entry_mode","num_of_transactions"
"Chip","17752"
"Contactless","17914"
"Swipe","17903"

-- 10. Identify terminals where the ratio of fraudulent to non-fraudulent transactions is abnormally high, 
-- but also has a significant number of total transactions (e.g., more than 50).

SELECT terminal_id,
  COUNT(transaction_id) AS total_transactions,
  SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END) AS fraudulent_transactions,
  ROUND(
        ( (SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END)::FLOAT / COUNT(transaction_id)::FLOAT) * 100 )::NUMERIC, 2
    ) AS fraud_percentage
FROM transactions
GROUP BY terminal_id
HAVING COUNT(transaction_id) > 500

"terminal_id","total_transactions","fraudulent_transactions","fraud_percentage"
"T001000","15528","476","3.07"
"T001001","21148","576","2.72"
"T001002","10202","320","3.14"
"T001003","13359","380","2.84"
"T001004","16556","585","3.53"
"T001005","12450","383","3.08"
"T001006","17693","501","2.83"
"T001007","23202","639","2.75"
"T001008","46131","1432","3.10"
"T001009","21984","688","3.13"
"T001010","14317","488","3.41"
"T001011","15749","510","3.24"
"T001012","12931","434","3.36"
"T001013","16116","415","2.58"
"T001014","21796","718","3.29"
"T001015","16407","535","3.26"
"T001016","15329","525","3.42"
"T001017","17006","464","2.73"
"T001018","9768","266","2.72"
"T001019","15380","426","2.77"
"T001020","29107","877","3.01"
"T001021","16497","472","2.86"
"T001022","16497","490","2.97"
"T001023","16967","490","2.89"
"T001024","14222","448","3.15"
"T001025","30243","855","2.83"
"T001026","14293","401","2.81"
"T001027","18692","549","2.94"
"T001028","15809","460","2.91"
"T001029","18651","561","3.01"
"T001030","15673","469","2.99"
"T001031","38442","1208","3.14"
"T001032","23780","704","2.96"
"T001033","21443","641","2.99"
"T001034","15893","449","2.83"
"T001035","23951","723","3.02"
"T001036","23779","640","2.69"
"T001037","16934","531","3.14"
"T001038","22043","659","2.99"
"T001039","15848","426","2.69"
"T001040","23968","797","3.33"
"T001041","12463","407","3.27"
"T001042","15770","483","3.06"
"T001043","18322","668","3.65"
"T001044","23762","781","3.29"
"T001045","12697","366","2.88"
"T001046","34862","1002","2.87"
"T001047","10001","259","2.59"
"T001048","14443","422","2.92"
"T001049","19198","565","2.94"
"T001050","18258","599","3.28"
"T001051","15896","474","2.98"
"T001052","13512","476","3.52"
"T001053","16106","456","2.83"
"T001054","15520","393","2.53"
"T001055","19602","575","2.93"
"T001056","13553","450","3.32"
"T001057","18625","616","3.31"
"T001058","16956","543","3.20"
"T001059","20303","653","3.22"
"T001060","17519","518","2.96"
"T001061","10243","320","3.12"
"T001062","14654","469","3.20"
"T001063","18424","494","2.68"
"T001064","14119","388","2.75"
"T001065","22198","726","3.27"
"T001066","30228","960","3.18"
"T001067","16183","457","2.82"
"T001068","13006","375","2.88"
"T001069","20232","584","2.89"
"T001070","25648","854","3.33"
"T001071","34472","1056","3.06"
"T001072","10386","273","2.63"
"T001073","13904","330","2.37"
"T001074","15740","461","2.93"
"T001075","15313","479","3.13"
"T001076","18651","526","2.82"
"T001077","15921","420","2.64"
"T001078","14954","422","2.82"
"T001079","17119","487","2.84"
"T001080","19966","556","2.78"
"T001081","13638","416","3.05"
"T001082","13033","386","2.96"
"T001083","13952","438","3.14"
"T001084","11298","326","2.89"
"T001085","12405","289","2.33"
"T001086","15707","475","3.02"
"T001087","18290","616","3.37"
"T001088","21362","628","2.94"
"T001089","15897","493","3.10"
"T001090","19671","582","2.96"
"T001091","15885","488","3.07"
"T001092","14017","462","3.30"
"T001093","14632","464","3.17"
"T001094","14691","454","3.09"
"T001095","14628","409","2.80"
"T001096","21397","602","2.81"
"T001097","16209","435","2.68"
"T001098","15641","429","2.74"
"T001099","8442","223","2.64"


-- 11. Identify customers whose transaction bin is most frequently associated with fraudulent activity.

SELECT customer_id,
  COUNT(bin) AS count_bin
FROM transactions
WHERE fraud = 1
GROUP BY customer_id
ORDER BY count_bin DESC ;


-- 12. For a single customer with both fraudulent and non-fraudulent transactions, 
-- what is the average distance from their home location to the terminal for both types of transactions?

    -- Find customers who have made both fraudulent and non-fraudulent transactions
WITH RelevantCustomers AS (
    SELECT
        customer_id
    FROM
        transactions
    GROUP BY
        customer_id
    HAVING
        COUNT(CASE WHEN fraud = 1 THEN 1 END) > 0
        AND COUNT(CASE WHEN fraud = 0 THEN 1 END) > 0
)

SELECT
    T.fraud,
    AVG(
        -- The Haversine formula to calculate distance in kilometers
        6371 * ACOS(
            SIN(RADIANS(CP.lat_customer)) * SIN(RADIANS(TP.lat_terminal))
            + COS(RADIANS(CP.lat_customer)) * COS(RADIANS(TP.lat_terminal)) * COS(RADIANS(CP.log_customer) - RADIANS(TP.log_terminal))
        )
    ) AS avg_distance_km
FROM
    transactions AS T
JOIN
    customer_profiles AS CP
ON
    T.customer_id = CP.customer_id
JOIN
    terminal_profiles AS TP
ON
    T.terminal_id = TP.terminal_id
WHERE
    T.customer_id IN (SELECT customer_id FROM RelevantCustomers)
GROUP BY
    T.fraud;

"fraud","avg_distance_km"
0,34.96322503280665
1,34.88483872362395

-- 13. How many unique customers made transactions at terminals that are also "available" to them according to the customer_terminal_map? 

SELECT
    COUNT(DISTINCT T.customer_id) AS num_customers_with_valid_transactions
FROM
    transactions AS T
JOIN
    customer_profiles AS CP ON T.customer_id = CP.customer_id
JOIN
    terminal_profiles AS TP ON T.terminal_id = TP.terminal_id
JOIN
    customer_terminal_map AS CTM ON T.customer_id = CTM.customer_id AND T.terminal_id = CTM.terminal_id;

"num_customers_with_valid_transactions"
"4991"


-- 14. List the top 3 terminals with the highest fraudulent transaction counts

SELECT terminal_id,
  COUNT(transaction_id) AS num_of_fraud_transactions
FROM transactions
WHERE fraud = 1
GROUP BY terminal_id
ORDER BY num_of_fraud_transactions DESC
LIMIT 3

"terminal_id","num_of_fraud_transactions"
"T001008","1432"
"T001031","1208"
"T001071","1056"


Fraud Analytics & Risk Scoring

-- 15. For each terminal, is the fraud rate in the last 30 days significantly higher than its prior 60-day baseline?

WITH RecentFraud AS (
    SELECT
        terminal_id,
        COUNT(transaction_id) AS total_transactions,
        SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END) AS fraudulent_transactions
    FROM
        transactions
    WHERE
        post_ts >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        terminal_id
),
PriorFraud AS (
    SELECT
        terminal_id,
        COUNT(transaction_id) AS total_transactions,
        SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END) AS fraudulent_transactions
    FROM
        transactions
    WHERE
        post_ts >= CURRENT_DATE - INTERVAL '90 days'
        AND post_ts < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        terminal_id
)
SELECT
    RF.terminal_id,
    ROUND((RF.fraudulent_transactions::FLOAT / RF.total_transactions::FLOAT * 100)::NUMERIC, 2) AS recent_fraud_rate_percentage,
    ROUND((PF.fraudulent_transactions::FLOAT / PF.total_transactions::FLOAT * 100)::NUMERIC, 2) AS prior_fraud_rate_percentage,
    ROUND(
        ( (RF.fraudulent_transactions::FLOAT / RF.total_transactions::FLOAT - PF.fraudulent_transactions::FLOAT / PF.total_transactions::FLOAT) 
        / (PF.fraudulent_transactions::FLOAT / PF.total_transactions::FLOAT) * 100
        )::NUMERIC, 2
    ) AS percentage_change
FROM
    RecentFraud AS RF
JOIN
    PriorFraud AS PF ON RF.terminal_id = PF.terminal_id
WHERE
    RF.total_transactions >= 10
    AND PF.total_transactions >= 10
    AND (RF.fraudulent_transactions::FLOAT / RF.total_transactions::FLOAT) > (PF.fraudulent_transactions::FLOAT / PF.total_transactions::FLOAT)
ORDER BY
    percentage_change DESC
LIMIT 10;

