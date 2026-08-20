-- 1.1 Invoice Clearance-Speed Distribution
-- What % of invoices clear same-day / next-day / within a week / are slow?
WITH paid AS (
    SELECT
        "Record ID" AS invoice_id,
        CAST("Amount billed" AS REAL) AS amount_billed,
        julianday("Payment date") - julianday("Invoice date") AS days_to_pay
    FROM invoices
    WHERE "Invoice status" = 'Paid'
      AND "Payment date" IS NOT NULL
      AND "Invoice date" IS NOT NULL
),
bucketed AS (
    SELECT
        CASE
            WHEN days_to_pay <= 0 THEN 'Same day'
            WHEN days_to_pay <= 1 THEN 'Next day'
            WHEN days_to_pay <= 7 THEN '2-7 days'
            WHEN days_to_pay <= 30 THEN '8-30 days'
            ELSE '30+ days'
        END AS clearance_bucket,
        amount_billed
    FROM paid
)
SELECT
    clearance_bucket,
    COUNT(*) AS invoice_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM bucketed), 1) AS pct_of_invoices,
    ROUND(SUM(amount_billed), 2) AS total_amount
FROM bucketed
GROUP BY clearance_bucket
ORDER BY
    CASE clearance_bucket
        WHEN 'Same day' THEN 1 WHEN 'Next day' THEN 2 WHEN '2-7 days' THEN 3
        WHEN '8-30 days' THEN 4 ELSE 5 END;
