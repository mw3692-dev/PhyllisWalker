SELECT
   STRFTIME('%Y-%m', i."Invoice date") AS "Invoice Month",
   CAST(c."Client Health Score" AS TEXT) AS "Health Score",  
   -- Total Revenue is the SUM of 'Amount billed' for ALL invoice statuses
   SUM(CAST(i."Amount billed" AS FLOAT)) AS "Total Revenue ($)", 
   -- Pending AR is the SUM of 'Amount billed' ONLY for 'Open' invoices
   SUM(CASE
           WHEN i."Invoice status" = 'Open' THEN CAST(i."Amount billed" AS FLOAT)
           ELSE 0
       END) AS "Pending AR ($)"
FROM
   "Invoices" i
JOIN
   -- NOTE: Direct CSV joins are complex if standard DB functions are unavailable.
   -- We join by extracting the first (primary) Company ID from the invoice's list.
   "active_clients" c
   ON SUBSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', 1, INSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', ';') - 1) = CAST(c."Record ID" AS TEXT)
WHERE
   -- 1. Filter for a complete timeframe: The last 6 complete months
   i."Invoice date" IS NOT NULL
   AND DATE(i."Invoice date") >= DATE('now', 'start of month', '-6 months')
   AND DATE(i."Invoice date") < DATE('now', 'start of month')
   -- 2. Ensure data validity for aggregation
   AND i."Invoice status" IN ('Paid', 'Open', 'Voided')
   AND c."Client Health Score" IS NOT NULL
   AND c."Client Health Score" <> 'NULL'
   AND i."Amount billed" IS NOT NULL
GROUP BY
   "Invoice Month",
   "Health Score"
ORDER BY
   "Invoice Month" ASC,
   CAST(c."Client Health Score" AS FLOAT) ASC;
