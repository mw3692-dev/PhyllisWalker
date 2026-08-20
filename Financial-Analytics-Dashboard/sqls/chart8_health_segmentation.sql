-- Chart 8: Executive Financial Health Segmentation (Monthly, by Client Health Score bucket)
-- See NOTES.md re: LIMIT -1 OFFSET 0 GROUP BY-after-JOIN workaround.
SELECT
    health_bucket, invoice_month,
    ROUND(SUM(CASE WHEN status='Paid' THEN amount_billed ELSE 0 END), 2) AS paid_revenue,
    ROUND(SUM(CASE WHEN status='Open' THEN balance_due ELSE 0 END), 2) AS open_ar
FROM (
    SELECT
        ac."Client Health Score" AS health_bucket,
        strftime('%Y-%m', i."Invoice date") AS invoice_month,
        i."Invoice status" AS status,
        CAST(i."Amount billed" AS REAL) AS amount_billed,
        CAST(i."Balance due" AS REAL) AS balance_due
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    WHERE ac."Client Health Score" IN ('Red','Amber','Green')
    LIMIT -1 OFFSET 0
)
GROUP BY health_bucket, invoice_month
ORDER BY health_bucket, invoice_month;
