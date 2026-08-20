-- Chart 6: Industry Revenue & Clearance Rate (Paid vs Open AR, all-time)
-- See NOTES.md re: LIMIT -1 OFFSET 0 GROUP BY-after-JOIN workaround.
SELECT
    industry,
    ROUND(SUM(CASE WHEN status='Paid' THEN amount_billed ELSE 0 END), 2) AS paid_revenue,
    ROUND(SUM(CASE WHEN status='Open' THEN balance_due ELSE 0 END), 2) AS open_ar
FROM (
    SELECT
        COALESCE(ac."Business Industry", 'Unclassified') AS industry,
        i."Invoice status" AS status,
        CAST(i."Amount billed" AS REAL) AS amount_billed,
        CAST(i."Balance due" AS REAL) AS balance_due
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    LIMIT -1 OFFSET 0
)
GROUP BY industry
ORDER BY paid_revenue DESC
LIMIT 10;
