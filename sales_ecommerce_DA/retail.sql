CREATE TABLE orders (
  Invoice     TEXT,
  StockCode     TEXT,
  Description   TEXT,
  Quantity      INTEGER,
  InvoiceDate   TEXT,
  Price         REAL,
  CustomerID    TEXT,
  Country       TEXT
);
SELECT
  SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customers,
  SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) AS missing_desc,
  SUM(CASE WHEN Price &amp;lt;= 0 THEN 1 ELSE 0 END) AS bad_prices,
  SUM(CASE WHEN Quantity &amp;lt;= 0 THEN 1 ELSE 0 END) AS returns_or_errors
FROM orders;

CREATE VIEW clean_orders AS SELECT * FROM orders
WHERE Quantity &gt; 0
AND Price &gt; 0
AND CustomerID IS NOT NULL
AND Invoice NOT LIKE 'C%';

CREATE VIEW rfm_raw AS
SELECT CustomerID,
       CAST(JULIANDAY('2011-12-31') - JULIANDAY((MAX(SUBSTR(InvoiceDate,7,4)||'-'||SUBSTR(InvoiceDate,4,2)||'-'||SUBSTR(InvoiceDate,1,2)))) AS INT) AS recency_Days,
	   COUNT(DISTINCT Invoice) AS frequency,
	   (SUM(Quantity * Price),2) AS monetary
FROM clean_orders
GROUP BY CustomerID;

CREATE VIEW rfm_scored AS SELECT CustomerID,
       recency_days,
	   frequency,
	   monetary,
	   CASE
	    WHEN recency_days &lt;= 150 THEN 5
		WHEN recency_days &lt;= 300 THEN 4
		WHEN recency_days &lt;= 450 THEN 3
		WHEN recency_days &lt;= 600 THEN 2
       ELSE 1 END AS r_score,
		CASE
         WHEN frequency &gt;= 280 THEN 5
         WHEN frequency &gt;= 210  THEN 4
         WHEN frequency &gt;= 140  THEN 3
		 WHEN frequency &gt;= 70 THEN 2
        ELSE 1 END AS f_score,
	    CASE
         WHEN monetary &gt;= 575000 THEN 5
         WHEN monetary &gt;= 460000 THEN 4
         WHEN monetary &gt;= 345000 THEN 3
		 WHEN monetary &gt;= 115000 THEN 2
        ELSE 1 END AS m_score
FROM rfm_raw;

CREATE VIEW rfm_segments AS
    SELECT CustomerID,
           recency_days,
           frequency,
           monetary,
           r_score,
           f_score,
           m_score,
          (r_score + f_score + m_score) AS rfm_total,
	   	  CASE
		   WHEN r_score = 5 AND f_score = 4 AND m_score = 5
           THEN 'Champion'
           WHEN r_score = 5 AND f_score &gt;= 4
           THEN 'Loyal Customer'
           WHEN r_score = 5 AND f_score &lt;= 3
           THEN 'New Customer'
           WHEN r_score = 4 AND f_score &gt;= 4
           THEN 'Potential Loyalist'
           WHEN r_score = 2 AND f_score &gt;= 3
           THEN 'At Risk'
           WHEN r_score = 1 AND f_score &gt;= 3
           THEN 'Lost Champion'
           WHEN r_score &lt;= 2 AND f_score &lt;= 2
           THEN 'Hibernating'
		   ELSE 'Needs Attention'
          END AS segment
FROM rfm_scored;

SELECT segment,
       COUNT(CustomerID) AS customer_count,
	   ROUND(AVG(recency_days)) AS avg_recency,
	   ROUND(AVG(frequency)) AS avg_frequency,
       ROUND(AVG(monetary), 2)  AS avg_spend,
       ROUND(SUM(monetary), 2)  AS total_revenue
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;

SELECT o.Invoice,
       o.InvoiceDate,
       o.CustomerID,
       o.Country,
       o.StockCode,
       o.Description,
       o.Quantity,
       o.Price,
       ROUND(o.Quantity * o.Price, 2) AS LineRevenue,
       s.segment,
       s.r_score,
       s.f_score,
       s.m_score,
       s.rfm_total
FROM clean_orders o
LEFT JOIN rfm_segments s
  ON o.CustomerID = s.CustomerID;
