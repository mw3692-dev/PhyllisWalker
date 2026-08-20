-- 1.2 DSO Trend by Invoice Month
-- Is average days-to-pay improving or worsening month over month?
-- NOTE: min/max included alongside avg since a handful of very slow-paying invoices
-- (e.g. Jan-26 had a 184-day outlier) can skew the mean - see report catalog doc.
SELECT
    strftime('%Y-%m', "Invoice date") AS invoice_month,
    COUNT(*) AS paid_invoices,
    ROUND(AVG(julianday("Payment date") - julianday("Invoice date")), 1) AS avg_days_to_pay,
    ROUND(MIN(julianday("Payment date") - julianday("Invoice date")), 1) AS min_days_to_pay,
    ROUND(MAX(julianday("Payment date") - julianday("Invoice date")), 1) AS max_days_to_pay
FROM invoices
WHERE "Invoice status" = 'Paid'
  AND "Payment date" IS NOT NULL AND "Invoice date" IS NOT NULL
GROUP BY invoice_month
ORDER BY invoice_month;
