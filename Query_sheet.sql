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
    num_transactions,
    CAST (AVG(num_transactions) OVER () AS DECIMAL(5, 2)) AS AVG_Num_of_Transactions
FROM
    customer_transaction_count
WHERE
    num_transactions > (SELECT AVG(num_transactions) FROM customer_transaction_count)
ORDER BY
    num_transactions DESC
LIMIT 50 ;

-- "customer_id","num_transactions","avg_num_of_transactions"
-- "C00001460","791","537.72"
-- "C00003273","789","537.72"
-- "C00002336","780","537.72"
-- "C00001313","775","537.72"
-- "C00004291","772","537.72"
-- "C00002490","771","537.72"
-- "C00003292","770","537.72"
-- "C00004485","768","537.72"
-- "C00003877","765","537.72"
-- "C00004868","761","537.72"
-- "C00004459","758","537.72"
-- "C00005122","756","537.72"
-- "C00001818","753","537.72"
-- "C00001673","753","537.72"
-- "C00002186","752","537.72"
-- "C00003765","750","537.72"
-- "C00001720","744","537.72"
-- "C00004012","744","537.72"
-- "C00001482","743","537.72"
-- "C00002902","743","537.72"
-- "C00001008","743","537.72"
-- "C00004222","738","537.72"
-- "C00005918","736","537.72"
-- "C00004692","736","537.72"
-- "C00003460","736","537.72"
-- "C00003157","735","537.72"
-- "C00004440","735","537.72"
-- "C00003557","734","537.72"
-- "C00002931","733","537.72"
-- "C00002359","733","537.72"
-- "C00005295","733","537.72"
-- "C00005118","731","537.72"
-- "C00001931","730","537.72"
-- "C00001197","730","537.72"
-- "C00005833","730","537.72"
-- "C00004765","730","537.72"
-- "C00005013","729","537.72"
-- "C00001586","729","537.72"
-- "C00001722","728","537.72"
-- "C00004937","727","537.72"
-- "C00004944","726","537.72"
-- "C00003459","724","537.72"
-- "C00003306","724","537.72"
-- "C00003068","721","537.72"
-- "C00003655","721","537.72"
-- "C00005479","720","537.72"
-- "C00002542","720","537.72"
-- "C00004330","719","537.72"
-- "C00001677","719","537.72"
-- "C00004203","719","537.72"


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
    fraud_transactions DESC
LIMIT 50;

-- "customer_id","fraud_transactions","nb_terminals"
-- "C00004868","57",13
-- "C00002186","55",11
-- "C00002069","48",8
-- "C00001313","47",9
-- "C00003306","46",12
-- "C00002462","44",7
-- "C00005177","44",11
-- "C00004870","43",7
-- "C00002112","42",7
-- "C00001944","42",15
-- "C00003411","41",7
-- "C00003466","40",9
-- "C00003605","40",7
-- "C00001023","39",8
-- "C00005909","39",8
-- "C00003598","39",11
-- "C00001447","39",9
-- "C00003750","38",7
-- "C00004164","38",7
-- "C00002613","38",7
-- "C00005245","37",8
-- "C00003765","37",7
-- "C00004925","37",7
-- "C00002982","37",7
-- "C00001439","37",7
-- "C00004252","36",9
-- "C00005195","36",8
-- "C00004222","36",10
-- "C00002122","35",7
-- "C00001824","35",12
-- "C00003399","35",7
-- "C00005781","35",7
-- "C00004937","35",9
-- "C00005151","35",9
-- "C00001308","34",10
-- "C00001027","34",9
-- "C00001868","34",8
-- "C00002958","34",11
-- "C00003872","34",7
-- "C00001482","34",9
-- "C00003687","34",7
-- "C00002026","34",9
-- "C00003748","34",9
-- "C00003983","34",7
-- "C00001386","34",7
-- "C00002142","34",7
-- "C00002904","34",9
-- "C00002428","33",9
-- "C00003353","33",11
-- "C00003335","33",9


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
  avg_customer_amt DESC
LIMIT 50 ;

-- "customer_id","avg_customer_amt"
-- "C00003639","121.68"
-- "C00005934","121.22"
-- "C00004057","117.46"
-- "C00005459","116.50"
-- "C00005272","115.52"
-- "C00002476","114.15"
-- "C00002431","112.61"
-- "C00002565","112.41"
-- "C00001813","111.38"
-- "C00005262","111.18"
-- "C00004762","110.17"
-- "C00005959","109.89"
-- "C00002485","109.70"
-- "C00002061","108.74"
-- "C00004325","108.71"
-- "C00002800","108.58"
-- "C00005298","108.42"
-- "C00003593","108.29"
-- "C00002550","107.93"
-- "C00001957","107.91"
-- "C00005084","107.90"
-- "C00004436","107.83"
-- "C00003981","107.64"
-- "C00002313","107.38"
-- "C00002533","107.27"
-- "C00001438","107.05"
-- "C00004381","106.88"
-- "C00005587","106.84"
-- "C00003300","106.65"
-- "C00002671","106.52"
-- "C00004224","106.48"
-- "C00004472","106.43"
-- "C00001087","106.37"
-- "C00002079","106.32"
-- "C00003733","106.28"
-- "C00003700","106.00"
-- "C00003238","105.98"
-- "C00002617","105.83"
-- "C00002241","105.82"
-- "C00002771","105.73"
-- "C00004474","105.70"
-- "C00004800","105.62"
-- "C00004581","105.60"
-- "C00001825","105.58"
-- "C00004839","105.44"
-- "C00005320","105.42"
-- "C00005567","105.35"
-- "C00001712","105.27"
-- "C00001186","105.18"
-- "C00004988","104.89"


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
ORDER BY count_bin DESC 
LIMIT 50;

-- "customer_id","count_bin"
-- "C00004868","57"
-- "C00002186","55"
-- "C00002154","51"
-- "C00005809","50"
-- "C00002917","49"
-- "C00002069","48"
-- "C00001313","47"
-- "C00001995","47"
-- "C00001590","46"
-- "C00003306","46"
-- "C00003243","45"
-- "C00002462","44"
-- "C00002075","44"
-- "C00005177","44"
-- "C00001525","44"
-- "C00005325","43"
-- "C00005874","43"
-- "C00004767","43"
-- "C00001123","43"
-- "C00004870","43"
-- "C00002112","42"
-- "C00003877","42"
-- "C00002383","42"
-- "C00005563","42"
-- "C00001944","42"
-- "C00002505","41"
-- "C00001373","41"
-- "C00002714","41"
-- "C00003411","41"
-- "C00003645","41"
-- "C00001063","41"
-- "C00004264","40"
-- "C00001514","40"
-- "C00001798","40"
-- "C00001188","40"
-- "C00003605","40"
-- "C00002382","40"
-- "C00001715","40"
-- "C00003466","40"
-- "C00001722","39"
-- "C00001447","39"
-- "C00003598","39"
-- "C00004903","39"
-- "C00002336","39"
-- "C00002329","39"
-- "C00005909","39"
-- "C00002195","39"
-- "C00002929","39"
-- "C00003459","39"
-- "C00001023","39"



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

-- 15. Among customers with fraud, do we see a pre/post behavior shift (avg amount, entry_mode mix) within ±14 days of first fraud?
-- Event study: windowed aggregates around first-fraud CTE.

WITH FirstFraudTimestamp AS (
  -- Step 1: Find the exact timestamp of the first fraudulent transaction for each customer.
  -- This is our "event" anchor point.
  SELECT
    customer_id,
    MIN(post_ts) AS first_fraud_ts
  FROM
    transactions
  WHERE
    fraud = 1
  GROUP BY
    customer_id
)
-- SELECT * FROM FirstFraudTimestamp ;
,
TransactionsInWindow AS (
  -- Step 2: Join back to the main transactions table and filter for the +/- 14 day window
  SELECT
    t.customer_id,
    t.post_ts,
    t.amt,
    t.entry_mode,
    t.fraud,
    ff.first_fraud_ts
  FROM
    transactions AS t
  INNER JOIN
    FirstFraudTimestamp AS ff
    ON t.customer_id = ff.customer_id
  WHERE
    -- Use date arithmetic to select transactions within the 14-day window around the first fraud.
    t.post_ts >= ff.first_fraud_ts - INTERVAL '14 DAY'
    AND t.post_ts <= ff.first_fraud_ts + INTERVAL '14 DAY'
)
-- SELECT * FROM TransactionsInWindow;
-- Step 3: Use conditional aggregation to calculate the average amount before and after the fraud event.
SELECT
  customer_id,
  -- Calculate the average amount for transactions before the fraud
  AVG(CASE WHEN post_ts < first_fraud_ts THEN amt ELSE NULL END) AS avg_amt_pre_fraud,
  -- Calculate the average amount for transactions after the fraud
  AVG(CASE WHEN post_ts >= first_fraud_ts THEN amt ELSE NULL END) AS avg_amt_post_fraud
FROM
  TransactionsInWindow
GROUP BY
  customer_id
ORDER BY
  avg_amt_post_fraud DESC
LIMIT 
  50;

-- "customer_id","avg_amt_pre_fraud","avg_amt_post_fraud"
-- "C00003631",60.75,239.03
-- "C00002919",113.79,202
-- "C00005453",107.4425,190.81
-- "C00004057","",182.84
-- "C00004799",110.6,178.02
-- "C00003751",76.17,174.91
-- "C00001183",56.84,166.365
-- "C00005580","",160.07
-- "C00003639",104.24666666666667,154.835
-- "C00001837",73.22999999999999,150.87
-- "C00005157",69.065,150.315
-- "C00001811",133.4075,149.94400000000002
-- "C00002161",72.49833333333333,148.808
-- "C00004168",73.77333333333333,148.54250000000002
-- "C00005645",92.97,146.71444444444444
-- "C00002533",90.895,143.67444444444445
-- "C00004091",84.3075,142.24444444444444
-- "C00001511",85.97333333333331,141.75
-- "C00004948",61.529999999999994,141.45
-- "C00001813",146.54333333333332,140.43666666666667
-- "C00001426",69.56400000000001,139.95
-- "C00001379",82.7975,139.54333333333332
-- "C00001571",95.20599999999999,139.54250000000002
-- "C00003415",61.35333333333333,139.21
-- "C00001608",106.07300000000001,138.42142857142858
-- "C00002183",85.36666666666667,138.10500000000002
-- "C00002366",116.85333333333334,136.45857142857142
-- "C00003690",98.85,134.62684210526314
-- "C00005235",103.888,133.0325
-- "C00003856",68.268,130.62333333333333
-- "C00002476",120.38833333333334,130.52399999999997
-- "C00002320","",130.1075
-- "C00003504","",130.0533333333333
-- "C00003212",62.88,130.03333333333333
-- "C00001768",80.771,129.81666666666663
-- "C00004787",100.23499999999999,129.50333333333333
-- "C00002789",70.03888888888889,129.01111111111112
-- "C00005932",91.21363636363635,128.96571428571428
-- "C00004214",100.398,128.66466666666668
-- "C00005770",115.00384615384615,128.1077777777778
-- "C00001680",107.8266666666667,127.61999999999999
-- "C00004310",116.37699999999998,127.57307692307693
-- "C00005926",96.32,127.46933333333332
-- "C00001057",84.31076923076922,127.1961111111111
-- "C00004955",56.91,127.00999999999999
-- "C00001343","",126.51
-- "C00002410",72.54375,126.50357142857145
-- "C00004762",123.05909090909091,126.24592592592593
-- "C00004281",125.50333333333333,125.85285714285715
-- "C00004436",92.41833333333334,125.47666666666666


-- 16. Identify customers whose terminal usage coverage = #(used ∩ available) / nb_terminals is <20% yet have high volume—does that correlate with fraud?


WITH CustomerUsedTerminals AS (
  -- Step 1: Count the number of UNIQUE terminals a customer has used.
  -- We also count total transactions and fraud for later analysis.
  SELECT
    customer_id,
    COUNT(DISTINCT terminal_id) AS used_terminals_count,
    COUNT(transaction_id) AS total_transactions,
    SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END) AS fraud_transactions
  FROM transactions
  GROUP BY customer_id
),
CustomerAvailableTerminals AS (
  -- Step 2: Count the total number of terminals available to each customer
  -- from the customer-terminal mapping table.
  SELECT
    customer_id,
    COUNT(DISTINCT terminal_id) AS available_terminals_count
  FROM customer_terminal_map
  GROUP BY customer_id
)

-- Step 3: Join the two CTEs and calculate the usage ratio.
-- Then, filter for low coverage and high transaction volume.
SELECT
  cu.customer_id,
  CAST(cu.used_terminals_count AS FLOAT) / ca.available_terminals_count AS terminal_coverage_ratio,
  cu.total_transactions,
  cu.fraud_transactions
FROM
  CustomerUsedTerminals AS cu
JOIN
  CustomerAvailableTerminals AS ca ON cu.customer_id = ca.customer_id
WHERE
  -- Filter for low terminal usage coverage (<20%)
  CAST(cu.used_terminals_count AS FLOAT) / ca.available_terminals_count < 0.20
  AND
  -- Filter for high transaction volume (adjust the number as needed)
  cu.total_transactions > 50
ORDER BY
  cu.fraud_transactions DESC,
  terminal_coverage_ratio ASC;

-- No data