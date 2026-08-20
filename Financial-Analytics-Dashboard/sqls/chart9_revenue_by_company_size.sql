-- Chart 9: Revenue Concentration by Company Size
-- Normalizes inconsistent "Employee range" text formats (e.g. "11-50 employees" vs "11 - 50").
-- See NOTES.md re: LIMIT -1 OFFSET 0 GROUP BY-after-JOIN workaround.
WITH normalized AS (
    SELECT
        ac."Record ID" AS client_id,
        CASE
            WHEN ac."Employee range" LIKE '2-10%' OR ac."Employee range" LIKE '1 - 10%' THEN '1-10'
            WHEN ac."Employee range" LIKE '11-50%' OR ac."Employee range" LIKE '11 - 50%' THEN '11-50'
            WHEN ac."Employee range" LIKE '51-200%' OR ac."Employee range" LIKE '51 - 200%' THEN '51-250'
            WHEN ac."Employee range" LIKE '201-500%' OR ac."Employee range" LIKE '501-1,000%' THEN '251-1000'
            WHEN ac."Employee range" LIKE '1,001-5,000%' OR ac."Employee range" LIKE '5,001-10,000%' THEN '1001-5000'
            ELSE NULL
        END AS size_bucket
    FROM active_clients ac
),
joined AS (
    SELECT n.size_bucket AS size_bucket, CAST(i."Amount billed" AS REAL) AS amount
    FROM invoices i
    JOIN normalized n ON n.client_id = i."Associated Company IDs"
    WHERE i."Invoice status" = 'Paid' AND n.size_bucket IS NOT NULL
    LIMIT -1 OFFSET 0
)
SELECT
    size_bucket,
    ROUND(SUM(amount), 2) AS paid_revenue,
    ROUND(100.0 * SUM(amount) / (SELECT SUM(amount) FROM joined), 1) AS pct_of_revenue
FROM joined
GROUP BY size_bucket
ORDER BY paid_revenue DESC;
