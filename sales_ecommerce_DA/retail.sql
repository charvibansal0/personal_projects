<?xml version="1.0" encoding="UTF-8"?><sqlb_project><db path="retail.db" readonly="0" foreign_keys="1" case_sensitive_like="0" temp_store="0" wal_autocheckpoint="1000" synchronous="2"/><attached/><window><main_tabs open="structure browser pragmas query" current="3"/></window><tab_structure><column_width id="0" width="300"/><column_width id="1" width="0"/><column_width id="2" width="100"/><column_width id="3" width="3807"/><column_width id="4" width="0"/><expanded_item id="0" parent="1"/><expanded_item id="1" parent="1"/><expanded_item id="2" parent="1"/><expanded_item id="3" parent="1"/></tab_structure><tab_browse><table title="rfm_raw" custom_title="0" dock_id="1" table="4,7:mainrfm_raw"/><dock_state state="000000ff00000000fd00000001000000020000015c0000030efc0100000001fb000000160064006f0063006b00420072006f007700730065003101000000000000015c0000012d00ffffff0000015c0000000000000004000000040000000800000008fc00000000"/><default_encoding codec=""/><browse_table_settings><table schema="main" name="clean_orders" show_row_id="0" encoding="" plot_x_axis="" unlock_view_pk="_rowid_" freeze_columns="0"><sort/><column_widths><column index="1" value="54"/><column index="2" value="67"/><column index="3" value="280"/><column index="4" value="56"/><column index="5" value="132"/><column index="6" value="46"/><column index="7" value="75"/><column index="8" value="117"/></column_widths><filter_values/><conditional_formats/><row_id_formats/><display_formats/><hidden_columns/><plot_y_axes/><global_filter/></table><table schema="main" name="orders" show_row_id="0" encoding="" plot_x_axis="" unlock_view_pk="_rowid_" freeze_columns="0"><sort><column index="3" mode="0"/></sort><column_widths><column index="1" value="62"/><column index="2" value="67"/><column index="3" value="280"/><column index="4" value="56"/><column index="5" value="132"/><column index="6" value="46"/><column index="7" value="75"/><column index="8" value="117"/></column_widths><filter_values/><conditional_formats/><row_id_formats/><display_formats/><hidden_columns/><plot_y_axes/><global_filter/></table><table schema="main" name="rfm_raw" show_row_id="0" encoding="" plot_x_axis="" unlock_view_pk="_rowid_" freeze_columns="0"><sort><column index="3" mode="1"/></sort><column_widths><column index="1" value="75"/><column index="2" value="85"/><column index="3" value="64"/><column index="4" value="93"/></column_widths><filter_values/><conditional_formats/><row_id_formats/><display_formats/><hidden_columns/><plot_y_axes/><global_filter/></table></browse_table_settings></tab_browse><tab_sql><sql name="SQL 1*">CREATE TABLE orders (
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

	   ROUND(SUM(Quantity * Price),2) AS monetary

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

  ON o.CustomerID = s.CustomerID;</sql><current_tab id="0"/></tab_sql></sqlb_project>
