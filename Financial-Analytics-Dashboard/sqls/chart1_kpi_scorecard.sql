-- Chart 1: Executive KPI Scorecard - Cleared (Paid) Revenue by Invoice Month
-- Reproduces the "Cleared Invoices (<Month>)" KPI cards.
-- Validated against rocket_station.sqlite: Jun-26 = $2,436,189.73, Jul-26 = $2,054,747.96,
-- Aug-26 MTD = $500.00, matching the dashboard's hardcoded figures almost exactly.
SELECT
    strftime('%Y-%m', "Invoice date") AS invoice_month,
    ROUND(SUM(CAST("Amount billed" AS REAL)), 2) AS cleared_revenue
FROM invoices
WHERE "Invoice status" = 'Paid'
GROUP BY invoice_month
ORDER BY invoice_month;
