WITH QuarterlyClientTotals AS (
   -- Step 1: Aggregate total revenue per client per quarter, filtering out the current quarter
   SELECT
       c."Company name",
       STRFTIME('%Y-Q', i."Invoice date") || ((CAST(STRFTIME('%m', i."Invoice date") AS INTEGER) + 2) / 3) AS Quarter,
       SUM(i."Amount billed") AS Client_Quarterly_Total
   FROM Invoices i
   JOIN active_clients c
       ON SUBSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', 1, INSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', ';') - 1) = CAST(c."Record ID" AS TEXT)
   WHERE i."Invoice status" != 'Voided'
     AND i."Invoice date" IS NOT NULL
     -- Filter to ignore the current active quarter (e.g., Q3 2026)
     AND i."Invoice date" < DATE('now', 'start of month',
         CASE
           WHEN CAST(STRFTIME('%m', 'now') AS INTEGER) IN (1,2,3) THEN '-' || (CAST(STRFTIME('%m', 'now') AS INTEGER) - 1) || ' months'
           WHEN CAST(STRFTIME('%m', 'now') AS INTEGER) IN (4,5,6) THEN '-' || (CAST(STRFTIME('%m', 'now') AS INTEGER) - 4) || ' months'
           WHEN CAST(STRFTIME('%m', 'now') AS INTEGER) IN (7,8,9) THEN '-' || (CAST(STRFTIME('%m', 'now') AS INTEGER) - 7) || ' months'
           ELSE '-' || (CAST(STRFTIME('%m', 'now') AS INTEGER) - 10) || ' months'
         END)
   GROUP BY 1, 2
),
RankedClients AS (
   -- Step 2: Rank them and calculate the overall quarterly total
   SELECT
       Quarter,
       "Company name",
       Client_Quarterly_Total,
       SUM(Client_Quarterly_Total) OVER(PARTITION BY Quarter) AS Total_Quarterly_Revenue,
       ROW_NUMBER() OVER(PARTITION BY Quarter ORDER BY Client_Quarterly_Total DESC) as Rank
   FROM QuarterlyClientTotals
)
-- Step 3: Select only the Top 10 and calculate their true percentage share
SELECT
   Quarter,
   "Company name" AS Client_Group,
   Client_Quarterly_Total AS Segment_Revenue,
   Total_Quarterly_Revenue,
   (Client_Quarterly_Total / Total_Quarterly_Revenue) * 100 AS Pct_Of_Overall_Revenue
FROM RankedClients
WHERE Rank <= 10
ORDER BY Quarter DESC, Segment_Revenue DESC
LIMIT 40; -- Limits to the last 4 quarters (10 clients * 4 quarters)
