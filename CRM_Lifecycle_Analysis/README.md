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
│   ├── 01_setup.sql            — create tables, load data
│   ├── 02_views.sql            — 5 reusable views (core of the analysis)
│   └── 03_analysis.sql         — 10 analysis queries built on views
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

## Key Findings

### Revenue Concentration
| Segment | Customers | % of Base | Revenue | % of Total |
|---|---|---|---|---|
| active | 700 | 35% | Rs 22,54,138 | 66.2% |
| at_risk | 500 | 25% | Rs 6,74,151 | 19.8% |
| churned | 400 | 20% | Rs 2,48,509 | 7.3% |
| new | 400 | 20% | Rs 2,48,036 | 7.3% |

**Active customers are 35% of the base but generate 66% of revenue.**
Revenue per active customer is 5.2× that of new or churned customers.

### Churn Risk
- 500 at-risk customers have gone silent for 25–50 days
- Their average lifetime value is Rs 1,348 each → Rs 6.7L at immediate risk
- Top 20 at-risk customers by LTV are the highest-urgency reactivation targets

### Win-Back Opportunity
| City | Churned Customers | Avg LTV | Recoverable Revenue |
|---|---|---|---|
| Bangalore | 209 | Rs 618 | Rs 1,29,212 |
| Hyderabad | 191 | Rs 625 | Rs 1,19,297 |

At an 8% win-back response rate: **Rs ~19,900 projected recovery**

### Campaign Uplift Model
| Segment | Audience | Response Rate | Projected Recovery |
|---|---|---|---|
| active | 700 | 55% | Rs 2,21,375 |
| at_risk | 500 | 22% | Rs 56,100 |
| new | 400 | 35% | Rs 63,000 |
| churned | 400 | 8% | Rs 12,480 |

### Campaign Brief
| Segment | Message | Mechanic | Success Metric |
|---|---|---|---|
| new | Onboarding nudge — complete your first repeat order | Push notification D+3 | D+7 second-order rate |
| active | Habit deepening — try a new category this week | Weekly email | Cross-category purchase rate |
| at_risk | Re-engagement — personalised offer | SMS + 10% voucher, 5-day expiry | Reactivation rate within 14 days |
| churned | Win-back — here's what changed | Email sequence: D0, D3, D7 | Win-back rate + recovered revenue |

---

## How to Run

**Requirements:** MySQL 8.0+ and MySQL Workbench

```sql
-- 1. Enable local CSV import (run once)
SET GLOBAL local_infile = 1;

-- 2. Run setup
source sql/01_setup.sql

-- 3. Create views
source sql/02_views.sql

-- 4. Run analysis
source sql/03_analysis.sql
```

Or open each file in MySQL Workbench and run sequentially.
Update the `/path/to/` in `01_setup.sql` to your local data folder before running.

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
