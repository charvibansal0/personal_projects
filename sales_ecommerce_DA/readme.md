E-commerce Sales & Customer Segmentation Analysis
End-to-end analysis of 1.07M transactions from a UK online retailer, covering
data cleaning, RFM customer segmentation in SQL, and an interactive Tableau
dashboard built for non-technical stakeholders.
Live dashboard: [add your Tableau Public link here]

Overview
This project takes a raw, messy transactional dataset and turns it into a
decision-ready view of who the customers are and where the revenue comes from.
The workflow is:

Clean the raw order data (remove returns, nulls, and invalid prices).
Segment every customer using RFM (Recency, Frequency, Monetary) scoring.
Visualise revenue trends, geography, and customer segments in Tableau.

The goal was a portfolio piece demonstrating the full analyst workflow — not just
writing queries, but cleaning real data, designing a segmentation model, and
communicating findings visually.
Dataset
Online Retail II — UCI Machine Learning Repository
https://archive.ics.uci.edu/dataset/502/online+retail+ii
Real transactional data from a UK-based online gift retailer covering
December 2009 – December 2011: 1,067,371 rows across two annual sheets and
40+ countries.
ColumnDescriptionInvoiceInvoice number (prefix C = cancellation)StockCodeProduct codeDescriptionProduct nameQuantityUnits per line itemInvoiceDateOrder date and timePriceUnit priceCustomerIDCustomer identifierCountryCustomer country
Tools

SQLite (via DB Browser for SQLite) — data cleaning, modelling, RFM logic
Tableau Public — interactive dashboard
Excel — initial .xlsx to .csv conversion

Repository contents
FileDescriptionretail_analysis.sqlAll SQL: schema, audit, cleaning view, RFM chain, exportsretail.sqbproDB Browser project fileREADME.mdThis file

The raw data and retail.db are not included (file size / licensing).
See Reproducing this project to rebuild from source.

Methodology
1. Data cleaning
A clean_orders view filters the raw table down to valid sales — removing
cancellations (Invoice starting with C), returns and errors (Quantity <= 0),
invalid pricing (Price <= 0), and rows with no CustomerID. This removed
261,822 rows (~24.5%), leaving 805,549 clean transactions from
5,878 customers. All downstream queries use clean_orders, so the cleaning
logic is defined once and applied consistently.
2. RFM customer segmentation
Customers are scored on three behavioural dimensions:
DimensionQuestion it answersRecencyHow recently did they buy?FrequencyHow often do they buy?MonetaryHow much have they spent?
