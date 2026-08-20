WITH ClientRiskT12M AS (
   -- Step 1: Calculate metrics for all clients with open invoices in T12M
   SELECT
       c."Company name",
       c."Business Industry", -- Kept for context
       SUM(i."Amount billed") AS Total_Open_Amount,
       AVG(CAST(SUBSTR(i."Days overdue (HH:mm:ss)", 1, INSTR(i."Days overdue (HH:mm:ss)", ':') - 1) AS FLOAT) / 24.0) AS Avg_Overdue_Days
   FROM Invoices i
   JOIN active_clients c
       ON SUBSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', 1, INSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', ';') - 1) = CAST(c."Record ID" AS TEXT)
   WHERE i."Invoice status" = 'Open'
     AND i."Invoice status" IS NOT NULL
     AND i."Invoice date" IS NOT NULL
     -- DATE RANGE: Aug 2025 - Jul 2026
     AND DATE(i."Invoice date") >= '2025-08-01'
     AND DATE(i."Invoice date") <= '2026-07-31'
   GROUP BY 1, 2
)
-- Step 2: Extract Top 10 by Open AR value
SELECT
   "Company name",
   "Business Industry",
   Total_Open_Amount,
   Avg_Overdue_Days
FROM ClientRiskT12M
ORDER BY Total_Open_Amount DESC
LIMIT 10;
