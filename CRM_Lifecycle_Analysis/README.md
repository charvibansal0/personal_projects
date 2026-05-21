# CRM Lifecycle Analysis — Quick Commerce App

End-to-end customer lifecycle analysis on a quick commerce grocery app dataset.
Built to understand how revenue is distributed across lifecycle stages, identify
customers at churn risk, and design data-backed CRM interventions per segment.

---

## Problem Statement

Quick commerce apps have high order frequency but also high churn — customers
who order daily one week can go completely silent the next. Without understanding
*why* customers lapse and *which* segments are most at risk, retention spend gets
distributed uniformly rather than where it actually matters.

**Three questions this project answers:**

1. Which lifecycle segments exist and how concentrated is revenue across them?
2. Which customers are at risk right now, and how urgent is the problem?
3. What CRM intervention should each segment receive, and what metric proves it worked?

---

## Dataset

Simulated dataset modelled on real quick commerce order patterns.

| File | Rows | Description |
|---|---|---|
| `data/customers.csv` | 2,000 | customer_id, lifecycle_segment, city, age_band |
| `data/orders.csv` | 6,425 | order_id, customer_id, order_date, order_value, category |

**Segments:** `new` · `active` · `at_risk` · `churned`  
**Date range:** Nov 2024 – Apr 2025  
**Cities:** Bangalore, Hyderabad  
**Categories:** Fruits & Vegetables, Dairy & Eggs, Packaged Grocery, Bakery, Beverages, Staples

---

## Project Structure

```
crm-lifecycle-analysis/
│
├── data/
│   ├── customers.csv           — customer master with segment labels
│   └── orders.csv              — full order history
│
├── sql/
│   ├── 01_setup                — create tables, load data
│   ├── 02_views                — 5 reusable views (core of the analysis)
│   └── 03_analysis             — 10 analysis queries built on views
│
├── outputs/
│   └── findings.md             — key numbers, segment tables, recommendations
│
├── images/
│   └── schema.png              — table relationship diagram (add after setup)
│
└── README.md
```

---

## Methodology

### Step 1 — View Architecture
Rather than repeating joins and recency calculations across every query, the
analysis is built on **5 reusable MySQL views**:

| View | What it computes | Used by |
|---|---|---|
| `customer_summary` | Per-customer: orders, LTV, AOV, recency via `DATEDIFF` | Queries 1, 2, 3, 4, 7, 8, 10 |
| `segment_stats` | Segment-level rollup: revenue, LTV, avg orders, recency | Queries 1, 2, 9, 10 |
| `category_orders` | Orders enriched with segment — avoids repeating JOIN | Queries 5, 6 |
| `at_risk_customers` | Pre-filtered: at-risk, 25–50 days silent | Query 7 |
| `churned_customers` | Pre-filtered: churned segment | Query 8 |

### Step 2 — Analysis Queries (10 total)

| # | Query | What it answers |
|---|---|---|
| 1 | Segment health check | How is the customer base distributed? |
| 2 | Revenue concentration | Which segments drive disproportionate value? |
| 3 | Recency list | How long has each customer been silent? |
| 4 | Order frequency distribution | How often does each segment order? |
| 5 | Category preference by segment | What does each segment buy? |
| 6 | Monthly engagement trend | Is activity growing or declining per segment? |
| 7 | At-risk priority list | Which at-risk customers need immediate action? |
| 8 | Win-back opportunity sizing | How much revenue is recoverable from churned? |
| 9 | Campaign brief table | What campaign should each segment receive? |
| 10 | Revenue uplift projection | How much revenue can campaigns recover? |

### Step 3 — Campaign Brief
Each lifecycle segment mapped to a specific message, delivery mechanic, and
success metric — structured the way a CRM team would actually brief execution.

---

How to Run
Requirements: MySQL 8.0+ and MySQL Workbench (free at dev.mysql.com)
```sql
-- 1. Enable local CSV import (run once)
SET GLOBAL local_infile = 1;

-- 2. Run setup
source crm.sql

-- 3. Create views

-- 4. Run analysis
```
Update the `/path/to/` in `crm.sql` to your local data folder before running.

---

## SQL Concepts Used

- **Window functions** — `COUNT(*) OVER()`, `SUM() OVER(PARTITION BY ...)` for % calculations
- **CTEs** — `WITH ... AS` for the uplift model response rate join
- **Views** — 5 reusable views eliminating repeated JOIN logic
- **Conditional aggregation** — `CASE WHEN` inside `AVG()` and `SUM()`
- **Date functions** — `DATEDIFF()` for recency, `DATE_FORMAT()` for monthly grouping
- **HAVING** — post-aggregation filter for at-risk customer identification
- **NULLIF** — safe division guard in drop-off calculations

---
