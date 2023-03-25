
-- 1) Provide the list of markets in which customer "Atliq Exclusive" operates 
-- its business in the APAC region.

SELECT market
FROM gdb023.dim_customer
WHERE region = 'APAC' and customer = 'Atliq Exclusive'

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

 WITH products_2020
AS
  (
	SELECT count(DISTINCT dp.product) AS unique_products_2020
	FROM   gdb023.fact_sales_monthly AS fsm
    JOIN gdb023.dim_product AS dp
    ON dp.product_code = fsm.product_code
	WHERE  fiscal_year = 2020),
    
  products_2021
AS
  (
	SELECT count(DISTINCT dp.product) AS unique_products_2021
	FROM   gdb023.fact_sales_monthly AS fsm
    JOIN gdb023.dim_product AS dp
    ON dp.product_code = fsm.product_code
	WHERE  fiscal_year = 2021)
    
  SELECT a.unique_products_2020,
         b.unique_products_2021,
         round(((b.unique_products_2021 - a.unique_products_2020)/a.unique_products_2020) *100 ,2) AS percentage_change
  FROM   products_2020  AS a
  JOIN   products_2021  AS b; 

-- 3) Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

SELECT Count(DISTINCT product) AS product_count, segment
FROM   gdb023.dim_product
GROUP  BY segment
ORDER  BY product_count DESC;  

-- 4)Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields, 
-- segment
-- product_count_2020
-- product_count_2021
-- difference

 WITH product_2020
     AS (SELECT Count(DISTINCT dp_1.product_code) AS product_count_2020,
                dp_1.segment
         FROM   gdb023.dim_product AS dp_1
                JOIN gdb023.fact_sales_monthly AS fsm_1
                  ON dp_1.product_code = fsm_1.product_code
         WHERE  fsm_1.fiscal_year = 2020
         GROUP  BY dp_1.segment),
     product_2021
     AS (SELECT Count(DISTINCT dp_2.product_code) AS product_count_2021,
                dp_2.segment
         FROM   gdb023.dim_product AS dp_2
                JOIN gdb023.fact_sales_monthly AS fsm_2
                  ON dp_2.product_code = fsm_2.product_code
         WHERE  fsm_2.fiscal_year = 2021
         GROUP  BY dp_2.segment)
SELECT pd_1.segment,
       pd_1.product_count_2020,
       pd_2.product_count_2021,
	  ( pd_2.product_count_2021 - pd_1.product_count_2020) AS difference
FROM   product_2020 AS pd_1
       JOIN product_2021 AS pd_2
         ON pd_1.segment = pd_2.segment
ORDER  BY difference DESC  

-- 5) Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

 WITH required
     AS (SELECT fmc.product_code,
                dp.product,
                fmc.manufacturing_cost
         FROM   gdb023.dim_product AS dp
                JOIN gdb023.fact_manufacturing_cost fmc
                  ON dp.product_code = fmc.product_code) 
SELECT *
FROM   required
WHERE  manufacturing_cost = (SELECT
       Max(manufacturing_cost) AS manufacturing_cost
                             FROM   gdb023.fact_manufacturing_cost)
UNION
SELECT *
FROM   required
WHERE  manufacturing_cost = (SELECT
            Min(manufacturing_cost) AS manufacturing_cost
                             FROM   gdb023.fact_manufacturing_cost)  
 
-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

SELECT dc.customer_code,
       dc.customer,
       Round(Avg(pid.pre_invoice_discount_pct) * 100, 2) AS
       avg_discount_percentage
FROM   gdb023.dim_customer AS dc
       JOIN gdb023.fact_pre_invoice_deductions AS pid
         ON dc.customer_code = pid.customer_code
WHERE  pid.fiscal_year = '2021'
       AND dc.market = 'India'
GROUP  BY pid.customer_code,
          dc.customer
ORDER  BY avg_discount_percentage DESC
LIMIT  5;  

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

SELECT Monthname(fsm.date) AS Month,
       Year(fsm.date) AS Year,
       Round(Sum(fgp.gross_price * fsm.sold_quantity), 2) AS Gross_Sales_Amount
FROM   gdb023.fact_sales_monthly fsm
       JOIN gdb023.dim_customer AS dc
         ON dc.customer_code = fsm.customer_code
       JOIN gdb023.fact_gross_price AS fgp
         ON fgp.product_code = fsm.product_code
WHERE  dc.customer = 'Atliq Exclusive'
GROUP  BY fsm.date
ORDER  BY year  

-- 8) In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

 SELECT CASE
         WHEN Month(fsm.date) IN ( 9, 10, 11 ) THEN 'Q1'
         WHEN Month(fsm.date) IN ( 12, 01, 02 ) THEN 'Q2'
         WHEN Month(fsm.date) IN ( 03, 04, 05 ) THEN 'Q3'
         WHEN Month(fsm.date) IN ( 06, 07, 08 ) THEN 'Q4'
       end                    AS quarter,
       Sum(fsm.sold_quantity) AS Total_sold_quantity
FROM   gdb023.fact_sales_monthly AS fsm
WHERE  fsm.fiscal_year = 2020
GROUP  BY quarter
ORDER  BY total_sold_quantity DESC  

-- 9) Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

 WITH gross_sales
     AS (SELECT dc.channel,
                Round(Sum(fgp.gross_price * fsm.sold_quantity) / 1000000, 2) AS
                   gross_sales_mln
         FROM   gdb023.fact_sales_monthly AS fsm
                JOIN gdb023.dim_customer AS dc
                  ON dc.customer_code = fsm.customer_code
                JOIN gdb023.fact_gross_price AS fgp
                  ON fgp.product_code = fsm.product_code
         WHERE  fsm.fiscal_year = 2021
         GROUP  BY dc.channel
         ORDER  BY gross_sales_mln DESC)
SELECT *,
       gs.gross_sales_mln * 100 / Sum(gs.gross_sales_mln)
                                    OVER() AS Percentage
FROM   gross_sales AS gs  

-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order

 WITH products_2021
     AS (SELECT dp.division,
                dp.product_code,
                dp.product,
                Sum(fsm.sold_quantity) AS total_sold_quantity
         FROM   gdb023.dim_product AS dp
                JOIN gdb023.fact_sales_monthly AS fsm
                  ON dp.product_code = fsm.product_code
         WHERE  fsm.fiscal_year = 2021
         GROUP  BY dp.product,
                   dp.product_code,
                   dp.division)
SELECT x.*
FROM   (SELECT *,
               Rank()
                 OVER (
                   partition BY p_21.division
                   ORDER BY p_21.total_sold_quantity DESC) AS rank_order
        FROM   products_2021 AS p_21) x
WHERE  x.rank_order < 4  