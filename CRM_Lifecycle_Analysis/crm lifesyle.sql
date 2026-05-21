# Create database and tables
CREATE DATABASE my_crm;
USE my_crm;

CREATE TABLE crm_customers( customer_id VARCHAR(20) PRIMARY KEY,
                            lifecycle_segment VARCHAR(20) ,
                            city VARCHAR(50) ,
                            age_band VARCHAR(15));

CREATE TABLE crm_orders( order_id VARCHAR(20) PRIMARY KEY,
						 customer_id VARCHAR(20),
						 order_date DATE,
						 order_value DECIMAL(5,2),
						 category  VARCHAR(100),
                         city VARCHAR(40) );

# Load data into tables
SET GLOBAL local_infile = 1;

SHOW VARIABLES LIKE 'local_infile';

SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/crm_orders.csv'
INTO TABLE crm_orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/crm_customers.csv'
INTO TABLE crm_customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# Total count of rows
 SELECT COUNT(*) FROM crm_orders;
 SELECT COUNT(*) FROM crm_customers;

## CREATING VIEWS
# VIEW 1: customer_summary
CREATE VIEW customer_summary AS
SELECT c.customer_id,
       c.lifecycle_segment,
       c.city,
       c.age_band,
       COUNT(o.order_id) AS total_orders,
       ROUND(SUM(o.order_value),2) AS lifetime_value,
       ROUND(AVG(o.order_value),2) AS avg_order_value,
       MIN(o.order_date) AS first_order_date,
       MAX(o.order_date) AS last_order_date,
       DATEDIFF('2025-04-30', MAX(o.order_date)) AS days_since_last_order
FROM crm_customers c
JOIN crm_orders o ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.lifecycle_segment,
    c.city,
    c.age_band;
    
# VIEW 2: segment_stats
CREATE VIEW segment_stats AS
SELECT lifecycle_segment,
    COUNT(customer_id) AS customer_count,
    ROUND(COUNT(customer_id) * 100.0 /
          SUM(COUNT(customer_id)) OVER (), 1) AS pct_of_base,
    ROUND(SUM(lifetime_value), 0) AS total_revenue,
    ROUND(AVG(lifetime_value), 0) AS avg_ltv,
    ROUND(AVG(avg_order_value), 0) AS avg_order_value,
    ROUND(AVG(total_orders), 1) AS avg_orders_per_customer,
    ROUND(AVG(days_since_last_order), 0) AS avg_recency_days
FROM customer_summary
GROUP BY lifecycle_segment;

# VIEW 3: category_orders
CREATE VIEW category_orders AS
SELECT o.order_id,
       o.order_date,
       o.order_value,
       o.category,
       c.lifecycle_segment,
       c.city,
       c.age_band
FROM crm_orders o
JOIN crm_customers c ON o.customer_id = c.customer_id;

# VIEW 4: at_risk_customers
CREATE VIEW at_risk_customers AS
SELECT customer_id,
       city,
       age_band,
       total_orders,
       lifetime_value,
       avg_order_value,
       days_since_last_order
FROM customer_summary
WHERE lifecycle_segment = 'at_risk'
  AND days_since_last_order BETWEEN 25 AND 50;
  
# VIEW 5: churned_customers
CREATE VIEW churned_customers AS
SELECT customer_id,
       city,
       age_band,
       total_orders,
       lifetime_value,
       avg_order_value,
       days_since_last_order
FROM customer_summary
WHERE lifecycle_segment = 'churned';

## ANALYSIS
# QUERY 1: Segment health check
SELECT lifecycle_segment,
       customer_count,
       pct_of_base,
       avg_recency_days
FROM segment_stats
ORDER BY customer_count DESC;

# QUERY 2: Revenue concentration by segment
SELECT lifecycle_segment,
       customer_count,
       total_revenue,
       avg_ltv,
       avg_order_value,
       ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 1) AS pct_of_total_revenue
FROM segment_stats
ORDER BY total_revenue DESC;

# QUERY 3: Full customer recency list 
SELECT
    customer_id,
    lifecycle_segment,
    city,
    last_order_date,
    days_since_last_order,
    lifetime_value
FROM customer_summary
ORDER BY days_since_last_order DESC;

# QUERY 4: Order frequency distribution
SELECT
    lifecycle_segment,
    total_orders,
    COUNT(*) AS num_customers
FROM customer_summary
GROUP BY lifecycle_segment, total_orders
ORDER BY lifecycle_segment, total_orders;

# QUERY 5: Category preference by segment
SELECT
    lifecycle_segment,
    category,
    COUNT(*) AS orders,
    ROUND(SUM(order_value), 0) AS revenue,
    ROUND(COUNT(*) * 100.0 /
          SUM(COUNT(*)) OVER (PARTITION BY lifecycle_segment), 1) AS pct_of_segment_orders
FROM category_orders
GROUP BY lifecycle_segment, category
ORDER BY lifecycle_segment, orders DESC;

# QUERY 6: Monthly engagement trend by segment
SELECT
    lifecycle_segment,
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(order_value), 0) AS revenue
FROM category_orders
GROUP BY lifecycle_segment, month
ORDER BY lifecycle_segment, month;
