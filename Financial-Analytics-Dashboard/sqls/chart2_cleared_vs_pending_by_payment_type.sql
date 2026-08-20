-- Chart 2: Cleared vs Pending Revenue by Payment Type (Automated NMI vs Manual Invoice)
-- CORRECTED: originally marked "cannot be reproduced" in NOTES.md because
-- invoices."Payment Collection Option"/"Invoice Tool Source" are empty. The real
-- source field is active_clients."Payment Method" (values: 'NMI - ACH',
-- 'NMI - Credit Card', 'Client Invoice') - found in a pre-existing SQL file that
-- appeared in this folder. Validated: numbers land within ~0.1% of the dashboard's
-- original hardcoded figures for the same billing cycles.
SELECT billing_cycle, automation_type,
       ROUND(SUM(CASE WHEN status='Paid' THEN amount ELSE 0 END), 2) AS cleared_amount,
       ROUND(SUM(CASE WHEN status='Open' THEN amount ELSE 0 END), 2) AS pending_amount
FROM (
    SELECT
        i."Billing Cycle" AS billing_cycle,
        CASE
            WHEN ac."Payment Method" IN ('NMI - ACH', 'NMI - Credit Card') THEN 'Automated (NMI)'
            WHEN ac."Payment Method" = 'Client Invoice' THEN 'Manual (Client Invoice)'
            ELSE 'Unknown/Other'
        END AS automation_type,
        i."Invoice status" AS status,
        CAST(i."Amount billed" AS REAL) AS amount
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    WHERE ac."Payment Method" IN ('NMI - ACH', 'NMI - Credit Card', 'Client Invoice')
      AND i."Invoice status" != 'Voided'
    LIMIT -1 OFFSET 0
)
GROUP BY billing_cycle, automation_type
ORDER BY billing_cycle DESC, automation_type;
