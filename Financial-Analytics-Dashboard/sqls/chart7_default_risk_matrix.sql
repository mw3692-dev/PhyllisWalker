-- Chart 7: Top Clients Default-Risk Matrix inputs
-- x = avg days overdue of open invoices, r/bubble-size = total open balance.
SELECT
    client_name,
    ROUND(AVG(days_overdue), 1) AS avg_days_overdue,
    ROUND(SUM(balance_due), 2) AS total_open_balance,
    COUNT(*) AS open_invoice_count
FROM (
    SELECT
        ac."Record ID" AS client_id,
        ac."Company name" AS client_name,
        julianday('now') - julianday(i."Due date") AS days_overdue,
        CAST(i."Balance due" AS REAL) AS balance_due
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    WHERE i."Invoice status" = 'Open'
    LIMIT -1 OFFSET 0
)
GROUP BY client_id
ORDER BY total_open_balance DESC
LIMIT 10;
