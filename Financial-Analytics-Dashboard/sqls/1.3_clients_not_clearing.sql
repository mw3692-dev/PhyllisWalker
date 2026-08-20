-- 1.3 Clients Whose Invoices Are Not Clearing
-- Which clients carry the largest open (unpaid) balance right now?
SELECT
    client_name, industry,
    COUNT(*) AS open_invoices,
    ROUND(SUM(balance_due), 2) AS total_open_balance
FROM (
    SELECT
        ac."Record ID" AS client_id,
        ac."Company name" AS client_name,
        ac."Business Industry" AS industry,
        CAST(i."Balance due" AS REAL) AS balance_due
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    WHERE i."Invoice status" = 'Open'
    LIMIT -1 OFFSET 0
)
GROUP BY client_id
ORDER BY total_open_balance DESC
LIMIT 10;
