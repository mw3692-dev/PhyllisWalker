SELECT
   CASE
       WHEN c."Employee range" IN ('1 - 10', '2-10 employees') THEN '1 - 10'
       WHEN c."Employee range" IN ('11 - 50', '11-50 employees') THEN '11 - 50'
       WHEN c."Employee range" IN ('51 - 250', '51-200 employees') THEN '51 - 250'
       ELSE 'Enterprise / Other'
   END AS Standardized_Employee_Range,
   COUNT(DISTINCT c."Record ID") AS Total_Clients,
   SUM(i."Amount billed") AS Total_Revenue
FROM Invoices i
JOIN active_clients c ON SUBSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', 1, INSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', ';') - 1) = CAST(c."Record ID" AS TEXT)
WHERE c."Employee range" IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC;
