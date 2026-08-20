-- Chart 5: Revenue Trends by Business Industry (Monthly)
-- See NOTES.md re: LIMIT -1 OFFSET 0 GROUP BY-after-JOIN workaround.
SELECT invoice_month, industry, ROUND(SUM(amount), 2) AS revenue
FROM (
    SELECT
        strftime('%Y-%m', i."Invoice date") AS invoice_month,
        COALESCE(ac."Business Industry", 'Unclassified') AS industry,
        CAST(i."Amount billed" AS REAL) AS amount
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    WHERE i."Invoice status" = 'Paid'
    LIMIT -1 OFFSET 0
)
GROUP BY invoice_month, industry
ORDER BY invoice_month, revenue DESC;
