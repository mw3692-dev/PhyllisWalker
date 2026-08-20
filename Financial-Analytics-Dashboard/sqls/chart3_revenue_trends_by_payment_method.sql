-- Chart 3: Total Revenue Trends by Payment Method
-- CORRECTED: see chart2_cleared_vs_pending_by_payment_type.sql for why this was
-- originally marked unreproducible and how that was wrong.
SELECT billing_cycle, payment_method,
       COUNT(*) AS invoice_count,
       ROUND(SUM(amount), 2) AS total_billed
FROM (
    SELECT
        i."Billing Cycle" AS billing_cycle,
        ac."Payment Method" AS payment_method,
        CAST(i."Amount billed" AS REAL) AS amount
    FROM invoices i
    JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
    WHERE ac."Payment Method" IN ('NMI - ACH', 'NMI - Credit Card', 'Client Invoice')
      AND i."Invoice status" != 'Voided'
    LIMIT -1 OFFSET 0
)
GROUP BY billing_cycle, payment_method
ORDER BY billing_cycle DESC, total_billed DESC;
