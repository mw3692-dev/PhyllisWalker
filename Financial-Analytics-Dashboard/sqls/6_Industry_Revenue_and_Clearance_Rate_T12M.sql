SELECT
   c."Business Industry",
   SUM(CASE WHEN i."Invoice status" = 'Paid' THEN i."Amount billed" ELSE 0 END) AS Paid_Revenue,
   SUM(CASE WHEN i."Invoice status" = 'Open' THEN i."Amount billed" ELSE 0 END) AS Open_Revenue
FROM Invoices i
JOIN active_clients c
   ON SUBSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', 1, INSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', ';') - 1) = CAST(c."Record ID" AS TEXT)
WHERE c."Business Industry" IS NOT NULL
 AND i."Invoice date" IS NOT NULL
 AND i."Invoice status" IN ('Paid', 'Open')
 -- TIMEFRAME: Trailing 12 Months (Excluding current partial month)
 AND DATE(i."Invoice date") >= DATE('now', 'start of month', '-12 months')
 AND DATE(i."Invoice date") < DATE('now', 'start of month')
GROUP BY 1
ORDER BY (Paid_Revenue + Open_Revenue) DESC;
