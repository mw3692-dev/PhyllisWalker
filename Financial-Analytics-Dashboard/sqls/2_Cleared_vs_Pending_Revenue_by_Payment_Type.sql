WITH PaymentCategories AS (
   SELECT
       CAST(c."Record ID" AS TEXT) AS Client_ID,
       CASE
           WHEN c."Payment Method" IN ('NMI - ACH', 'NMI - Credit Card') THEN 'Automated (NMI)'
           WHEN c."Payment Method" = 'Client Invoice' THEN 'Manual (Client Invoice)'
           ELSE 'Unknown/Other'
       END AS Automation_Type
   FROM active_clients c
)
SELECT
   i."Billing Cycle",
   p.Automation_Type,
   SUM(CASE WHEN i."Invoice status" = 'Paid' THEN i."Amount billed" ELSE 0 END) AS Cleared_Amount,
   SUM(CASE WHEN i."Invoice status" = 'Open' THEN i."Amount billed" ELSE 0 END) AS Pending_Amount
FROM Invoices i
JOIN PaymentCategories p
   ON SUBSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', 1, INSTR(REPLACE(i."Associated Company IDs", ',', ';') || ';', ';') - 1) = p.Client_ID
WHERE p.Automation_Type != 'Unknown/Other'
 AND i."Invoice status" != 'Voided'
 AND i."Billing Cycle" IN (
     'Apr 26, 2026 - May 10, 2026', 'May 11, 2026 - May 25, 2026',
     'May 26, 2026 - Jun 10, 2026', 'Jun 11, 2026 - Jun 25, 2026',
     'Jun 26, 2026 - Jul 10, 2026', 'Jul 11, 2026 - Jul 25, 2026'
 )
GROUP BY 1, 2
ORDER BY
   CAST(SUBSTR(i."Billing Cycle", 1, INSTR(i."Billing Cycle", '-') - 1) AS DATE),
   p.Automation_Type;
