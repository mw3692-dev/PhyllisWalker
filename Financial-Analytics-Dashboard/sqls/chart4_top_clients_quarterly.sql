-- Chart 4: Top 10 Clients Revenue Share (Quarterly)
-- NOTE: the inner "raw" CTE is intentionally materialized with LIMIT -1 OFFSET 0.
-- See NOTES.md - this blocks a GROUP BY-after-JOIN bug found in older SQLite engines
-- that silently split a single group into many when grouping a joined-in text column.
WITH raw AS (
    SELECT
        ac."Company name" AS client_name,
        i."Invoice date" AS invoice_date,
        CAST(i."Amount billed" AS REAL) AS amount
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    WHERE i."Invoice status" = 'Paid'
    LIMIT -1 OFFSET 0
),
q_rev AS (
    SELECT
        client_name,
        CASE
            WHEN CAST(strftime('%m', invoice_date) AS INT) <= 3 THEN strftime('%Y', invoice_date) || 'Q1'
            WHEN CAST(strftime('%m', invoice_date) AS INT) <= 6 THEN strftime('%Y', invoice_date) || 'Q2'
            WHEN CAST(strftime('%m', invoice_date) AS INT) <= 9 THEN strftime('%Y', invoice_date) || 'Q3'
            ELSE strftime('%Y', invoice_date) || 'Q4'
        END AS quarter,
        amount
    FROM raw
),
top_clients AS (
    SELECT client_name FROM q_rev GROUP BY client_name ORDER BY SUM(amount) DESC LIMIT 10
)
SELECT quarter, client_name, ROUND(SUM(amount), 2) AS revenue
FROM q_rev
WHERE client_name IN (SELECT client_name FROM top_clients)
GROUP BY quarter, client_name
ORDER BY quarter, revenue DESC;
