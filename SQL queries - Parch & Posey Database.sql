--What is the MEDIAN total_usd spent on all orders?

SELECT AVG(t2.total_amt_usd)
FROM (SELECT *
      FROM (SELECT total_amt_usd
         FROM orders
         ORDER BY total_amt_usd
         LIMIT 3457) AS Table1
      ORDER BY total_amt_usd DESC
      LIMIT 2) As t2;

--Provide the name for each region for every order, as well as the account name and the unit price for the order
--You should only provide the results if the standard order quantity exceeds 100 and the poster order quantity exceeds 50.

SELECT r.name region_name, a.name acc_name, o.total_amt_usd/o.total unitprice
FROM accounts a
JOIN sales_reps s
    ON a.sales_rep_id = s.id
JOIN region r
    ON s.region_id = r.id 
JOIN orders o
    ON o.account_id = a.id
WHERE o.standard_qty>100 AND o.poster_qty>50
Order BY unitprice DESC;

--The average amount for each type of paper sold on the first month that any order was placed in the orders table (in terms of quantity)

SELECT AVG(standard_qty) standard, AVG(gloss_qty) gloss, AVG(poster_qty) poster
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
     (SELECT DATE_TRUNC('month', Min(occurred_at))
      FROM orders);

--For the customer that spent the most total_amt_usd, how many web_events did they have for each channel

SELECT a.name accname, w.channel, COUNT(*) num_event
FROM accounts a
JOIN web_events w
    ON w.account_id = a.id
GROUP BY 1,2
HAVING a.name =
      (SELECT name
       FROM
           (SELECT a.name, SUM(total_amt_usd) totalspend
            FROM accounts a
            JOIN orders o
                ON o.account_id = a.id
            JOIN web_events w
                ON w.account_id = a.id
            GROUP BY 1
            ORDER BY 2 DESC
            LIMIT 1) t1);

--Create a running total of over order time, date truncate by year and partition by that same year-truncated.

SELECT standard_amt_usd, DATE_TRUNC('year',occurred_at), 
       (SUM(standard_amt_usd) OVER 
       (PARTITION BY DATE_TRUNC('year',occurred_at)
       ORDER BY occurred_at)) AS total_running
FROM orders;

--Create a column called total_rank that ranks this total amount of paper ordered (from highest to lowest) for each account using a partition.

SELECT id, account_id, total, 
       RANK() OVER
       (PARTITION BY account_id
       ORDER BY total DESC) AS total_rank
FROM orders;

--Determine how the current order's total revenue ("total" meaning from sales of all types of paper) compares to the next order's total revenue.

SELECT occurred_at, total_amt_usd,       
       LEAD(total_amt_usd) OVER (ORDER BY occurred_at) AS lead,       
       LEAD(total_amt_usd) OVER (ORDER BY occurred_at) - total_amt_usd AS lead_difference
FROM orders;

--Consider vowels as a, e, i, o, and u. What proportion of company names start with a vowel, and what percent start with anything else?

WITH sub AS 
(SELECT LEFT(name,1),
       (CASE WHEN LEFT(LOWER(name),1) IN ('a','e','i','o','u') 
            THEN 'Yes'
            ELSE 'NO' END) format
FROM accounts)

SELECT format, COUNT(*)
FROM sub
GROUP BY 1;

--Each company in the accounts table wants to create an email address for each primary_poc 
--The email address should be the first name of the primary_poc . last name primary_poc @ company name .com.

WITH t1 AS (
    SELECT LEFT(primary_poc, STRPOS(primary_poc, ' ') -1 ) first_name, RIGHT(primary_poc, LENGTH(primary_poc) - STRPOS(primary_poc, ' ')) last_name, name
    FROM accounts)
SELECT first_name, last_name, CONCAT(first_name, '.', last_name, '@', name, '.com')
FROM t1;
