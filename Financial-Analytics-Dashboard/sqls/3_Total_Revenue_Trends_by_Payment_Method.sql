SELECT
   i."Billing Cycle",
   c."Payment Method",
   COUNT(i."Record ID") AS Total_Invoices,
   SUM(i."Amount billed") AS Total_Billed_Amount
FROM Invoices i
JOIN active_clients c
   ON SUBSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', 1, INSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', ';') - 1) = CAST(c."Record ID" AS TEXT)
WHERE c."Payment Method" IN ('NMI - ACH', 'NMI - Credit Card', 'Client Invoice')
 AND i."Invoice status" != 'Voided'
 AND i."Billing Cycle" IN (
     'Apr 26, 2026 - May 10, 2026', 'May 11, 2026 - May 25, 2026',
     'May 26, 2026 - Jun 10, 2026', 'Jun 11, 2026 - Jun 25, 2026',
     'Jun 26, 2026 - Jul 10, 2026', 'Jul 11, 2026 - Jul 25, 2026'
 )
GROUP BY 1, 2
ORDER BY
   CAST(SUBSTR(i."Billing Cycle", 1, INSTR(i."Billing Cycle", '-') - 1) AS DATE),
   Total_Billed_Amount DESC;
