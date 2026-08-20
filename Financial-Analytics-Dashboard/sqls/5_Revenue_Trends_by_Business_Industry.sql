SELECT
   c."Business Industry",
   STRFTIME('%Y-%m', i."Invoice date") AS Invoice_Month,
   SUM(i."Amount billed") AS Total_Billed_Revenue
FROM Invoices i
JOIN active_clients c
   ON SUBSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', 1, INSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', ';') - 1) = CAST(c."Record ID" AS TEXT)
WHERE i."Invoice status" != 'Voided'
 AND c."Business Industry" IS NOT NULL
 AND i."Invoice date" IS NOT NULL
 AND STRFTIME('%Y-%m', i."Invoice date") < STRFTIME('%Y-%m', 'now')
GROUP BY 1, 2
ORDER BY 2 DESC, 3 DESC;
