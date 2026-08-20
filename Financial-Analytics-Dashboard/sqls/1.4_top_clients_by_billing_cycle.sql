-- 1.4 Top Clients by Billing-Cycle Revenue
-- Which clients generate the highest invoiced revenue for a given billing cycle?
SELECT
    billing_cycle, client_name,
    COUNT(*) AS invoice_count,
    ROUND(SUM(amount_billed), 2) AS total_billed
FROM (
    SELECT
        i."Billing Cycle" AS billing_cycle,
        ac."Record ID" AS client_id,
        ac."Company name" AS client_name,
        CAST(i."Amount billed" AS REAL) AS amount_billed
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    WHERE i."Billing Cycle" IS NOT NULL
    LIMIT -1 OFFSET 0
)
GROUP BY billing_cycle, client_id
ORDER BY billing_cycle DESC, total_billed DESC
LIMIT 10;
