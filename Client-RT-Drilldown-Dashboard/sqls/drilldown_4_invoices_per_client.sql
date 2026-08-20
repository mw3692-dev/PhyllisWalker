-- Client → RT Drill-down, query 4 of 6: invoice line items per client
-- Powers the "Actual Billing" summary strip. Raw line items are returned
-- (not pre-aggregated) - the page aggregates client-side so it can show both
-- an all-time total (Roster Summary tab) and a total restricted to the same
-- date range as RT hours (Hours & Billing Detail tab) from the same data.
SELECT
    ac."Record ID" AS client_id,
    ac."Company name" AS client_name,
    date(i."Invoice date") AS invoice_date,
    i."Invoice status" AS status,
    CAST(i."Amount billed" AS REAL) AS amount_billed,
    CAST(i."Balance due" AS REAL) AS balance_due
FROM invoices i
JOIN active_clients ac ON ac."Record ID" = i."Associated Company IDs"
WHERE i."Invoice status" != 'Voided'
ORDER BY ac."Company name", invoice_date;
