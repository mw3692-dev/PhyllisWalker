-- Client → RT Drill-down, query 6 of 6: parent/child company families
-- Powers the "Parent Company" treemap grouping - only clients that are part
-- of a multi-entity family (a parent company with 1+ related sub-accounts)
-- are shown in that view, grouped by the parent's company name.
-- NOTE: a family's member set is the parent's own row PLUS every ID listed in
-- "Child Company IDs" - the parent is a member of its own family (not just a
-- container), so it gets its own tile there too when it has active RTs. Some
-- listed child IDs don't have their own row in active_clients.csv at all
-- (present in HubSpot's org hierarchy but absent from this export) - those
-- can't be tiled since there's no client record for them, though they may
-- still contribute RT/invoice rows directly under their own ID elsewhere.
SELECT
    "Record ID" AS parent_id,
    "Company name" AS parent_name,
    "Child Company IDs" AS child_ids,
    CAST("Number of child companies" AS REAL) AS child_count_claimed
FROM active_clients
WHERE "Child Company IDs" IS NOT NULL AND TRIM("Child Company IDs") != ''
ORDER BY child_count_claimed DESC;
