-- Average Revenue Per User

WITH monthly_ARPM AS
(
SELECT
     m.visit_month, 
     AVG(m.revenue) AS ARPU 
FROM
     (SELECT
          uspm.user_id,
          DATE_PART('MONTH', AGE('2014-03-01', transaction_ts)) AS visit_month, 
          SUM(amount) AS revenue 
     FROM   transactions_fact tf
      INNER JOIN User_Saved_Payment_Modes uspm
      ON tf.uspm_id = uspm.uspm_id
      AND tf.transaction_type = 'Charge'
     WHERE  transaction_ts > CURRENT_DATE - INTERVAL '1 year'
     GROUP BY
           1, 
           2) m
GROUP BY 1
)
SELECT AVG(ARPU) AS AVG_ARPU
FROM monthly_ARPM

/* eg.

monthly_ARPM
| visit_month | ARPU       |
|-------------|------------|
|           7 |    1000.00 |
|           8 |    800.00  |
|           9 |    1200.00 |

Average_ARPM
1000.00

*/

---------------------------------------------------------------------------------------------------------------

-- Average Churn Rate

WITH monthly_visits AS 
(SELECT
     DISTINCT
     DATE_PART('MONTH', AGE('2014-03-01', transaction_ts)) AS visit_month, 
     user_id 
FROM  transactions_fact tf
 INNER JOIN User_Saved_Payment_Modes uspm
 ON tf.uspm_id = uspm.uspm_id
WHERE transaction_ts > CURRENT_DATE - INTERVAL '1 year')

SELECT
AVG(churn_rate) AS avg_churn_rate
FROM
     (SELECT
          current_month, 
          COUNT(CASE 
               WHEN cust_type='churn' THEN 1 
               ELSE NULL END)/COUNT(user_id) AS churn_rate 
     FROM
          (SELECT
               past_month.visit_month + 1 AS current_month, 
               past_month.user_id, 
               CASE
                    WHEN this_month.user_id IS NULL THEN 'churn' 
                    ELSE 'retained' 
               END AS cust_type 
          FROM
               monthly_visits past_month 
  	       LEFT JOIN monthly_visits this_month ON
                    this_month.user_id=past_month.user_id
                    AND this_month.visit_month=past_month.visit_month + 1
          )data
     GROUP BY 1) m

/*
eg.

AVG_CHURN_RATE
0.1

*/

---------------------------------------------------------------------------------------------------------------

-- Estimated Life-time value (overall average for any user)
SELECT (AVG_ARPU / AVG_CHURN_RATE) AS LTU

/* eg.

LTU
10000.0

*/

---------------------------------------------------------------------------------------------------------------

-- Customers returned from January for current year, till date

WITH January_pool AS
(
  SELECT DISTINCT user_id
  FROM transactions_fact tf
    INNER JOIN User_Saved_Payment_Modes uspm ON tf.uspm_id = uspm.uspm_id
  WHERE EXTRACT(Month FROM transaction_ts) = 1
  AND EXTRACT (Year FROM transaction_ts) = EXTRACT (Year FROM CURRENT_DATE)
  )
SELECT EXTRACT(Year FROM transaction_ts),
       EXTRACT(Month FROM transaction_ts),
       Count(DISTINCT user_id) AS num_users
FROM transactions_fact tf
  INNER JOIN User_Saved_Payment_Modes uspm ON tf.uspm_id = uspm.uspm_id
WHERE EXTRACT (Year FROM transaction_ts) = EXTRACT (Year FROM CURRENT_DATE)
AND user_id IN (SELECT * FROM January_pool)
GROUP BY 1,2

/*
eg.
| YEAR(transaction_ts) | MONTH(transaction_ts) | num_users |
|----------------------|-----------------------|---------- |
|                 2018 |                     1 |      1000 |
|                 2018 |                     2 |       800 |
|                 2018 |                     3 |       400 |

*/

---------------------------------------------------------------------------------------------------------------

-- Calculating customer retention for each month

WITH visit_log AS (
  SELECT
      user_id,
      DATE_PART('MONTH', AGE('2014-03-01', transaction_ts)) AS visit_month
     FROM   transactions_fact tf
      INNER JOIN User_Saved_Payment_Modes uspm ON tf.uspm_id = uspm.uspm_id
  GROUP BY 1, 2
  ORDER BY 1, 2
  ),

time_lapse AS (
  SELECT user_id,
     visit_month,
     lag(visit_month, 1) over (partition BY user_id ORDER BY user_id, visit_month) AS lag
   FROM visit_log
   ),

time_diff_calculated AS (
  SELECT user_id,
     visit_month,
     lag,
     visit_month - lag AS time_diff
   FROM time_lapse
   ),

custs_categorized AS (
  SELECT user_id,
     visit_month,
     lag,
     time_diff,
     (CASE
        WHEN time_diff=1 THEN 'retained'
        WHEN time_diff>1 THEN 'returning'
        WHEN time_diff IS NULL THEN 'new'
     END) AS cust_type
  FROM time_diff_calculated
  )

SELECT 
  visit_month,
  cust_type,
  Count(user_id) AS num_users
FROM custs_categorized
GROUP BY 1, 2

/* eg.

Custs_categorized
| user_id | visit_month | lag  | time_diff | cust_type |
|---------|-------------|------|-----------|-----------|
|   00001 |           1 | null |      null |       new |
|   00001 |           3 |    1 |         2 | returning |
|   00002 |           2 | null |      null |       new |
|   00002 |           3 |    2 |         1 |  retained |
|   00002 |           4 |    3 |         1 |  retained |


| visit_month | Cust_Type  | num_users |
|-------------|------------|-----------|
|           1 |        New |         1 |
|           2 |        New |         1 |
|           3 |  Returning |         1 |
|           3 |   Retained |         1 |
|           4 |   Retained |         1 |

*/

---------------------------------------------------------------------------------------------------------------

-- Cohort Analysis and Customer Retention

WITH visit_log AS (
  SELECT
      user_id,
      DATE_PART('MONTH', AGE('2014-03-01', transaction_ts)) AS visit_month
     FROM   transactions_fact tf
      INNER JOIN User_Saved_Payment_Modes uspm ON tf.uspm_id = uspm.uspm_id
  GROUP BY 1, 2
  ORDER BY 1, 2
  ),

first_visit AS (
    SELECT user_id,
      Min(visit_month) AS first_month   -- cohort
    FROM visit_log
    GROUP BY 1
    ),

New_users AS (
    SELECT first_month,
      Count(DISTINCT user_id) AS new_users
    FROM first_visit
    GROUP BY 1
    )

SELECT 
 first_month,
 new_users,
 retention_month,
 retained,
 retention_percentage
FROM (
  SELECT first_visit.first_month,
     new_users,
    ( visit_tracker.visit_month - visit_log.visit_month ) AS retention_month,
    Count(DISTINCT visit_tracker.user_id) AS retained,
    Count(DISTINCT visit_tracker.user_id)/new_users AS retention_percentage
  FROM visit_log
  LEFT JOIN visit_log AS visit_tracker
     ON visit_log.user_id = visit_tracker.user_id
        AND visit_log.visit_month < visit_tracker.visit_month
  LEFT JOIN first_visit 
    ON first_visit.user_id = visit_log.user_id
   LEFT JOIN new_users
     ON new_users.first_month = first_visit.first_month
GROUP BY 1, 2, 3) M


/* eg.

| first_month | new_users | retention_month  | retained | retention_percentage |
|-------------|-----------|------------------|----------|----------------------|
|           1 |       600 |                1 |      550 |               0.9166 |
|           1 |       600 |                2 |      525 |                0.875 |
|           1 |       600 |                3 |      500 |               0.8333 |
|           1 |       600 |                4 |      475 |               0.7916 |
|           2 |       500 |                1 |      400 |                  0.8 |
|           2 |       500 |                2 |      350 |                  0.7 |
|           2 |       500 |                3 |      300 |                  0.6 |
*/
---------------------------------------------------------------------------------------------------------------

-- Estimated Lifetime Value (LTV) per Customer

WITH cust_spending_pattern AS (
  SELECT
    user_id,
    DATE_PART('DAY', AGE(Min(transaction_ts), CURRENT_DATE)) AS days_from_first_txn, 
    DATE_PART('DAY', AGE(Max(transaction_ts), CURRENT_DATE)) AS days_from_last_txn, 
    Count(transaction_id) AS freq,
    Avg(amount) AS avg_spend
     FROM   transactions_fact tf
      INNER JOIN User_Saved_Payment_Modes uspm ON tf.uspm_id = uspm.uspm_id
      AND tf.transaction_type = 'Charge'    
  WHERE transaction_ts > CURRENT_DATE - INTERVAL '1 year'
  GROUP BY 1
  ORDER BY 4 DESC
  ),
cust_monthly AS (
  SELECT
    user_id,
    days_from_first_txn,
    days_from_last_txn,
    freq/((days_from_last_txn - days_from_first_txn)/30)*avg_spend AS monthly_spend
    FROM cust_spending_pattern
    )
SELECT
  user_id,
  days_from_last_txn/30 AS months_since_visit,
  days_from_last_txn/30 * (1-0.1) * monthly_spend AS next_month_estimate
  FROM cust_monthly
  ORDER BY 3 DESC
