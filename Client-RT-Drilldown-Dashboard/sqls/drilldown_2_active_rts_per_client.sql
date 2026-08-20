-- Client → RT Drill-down, query 2 of 6: active RT roster per client, with rates
-- Powers the RT table shown after clicking a client tile.
-- NOTE 1: "Client Base Rate" is 100% empty in the source data - excluded.
-- NOTE 2: "Role Title (External)" is used for role_title, not "Remote Teammate
-- Title" (always just "<RT Name> - <Contractor ID>", 100% unique per row, useless
-- for grouping RTs by role).
-- NOTE 3 (rate fields, confirmed against RS's own field definitions + validated
-- against real data): RS - Base Rate and Current Rate with Client are BOTH
-- cost-side (what RS pays the RT) - Current Rate with Client is RS Base Rate
-- plus any client-funded raise (never below RS Base Rate: 0 rows contradict
-- this). Partner Rate is the actual client-BILLING rate - confirmed distinct
-- from Current Rate with Client (averages 2.2x higher on the same row, range
-- 0-3.5x, not a rounding difference). Fixed Rate is a flat monthly override for
-- clients billed a fixed fee instead of hourly (Brookfield Properties
-- sub-accounts only, in this data, ~1% of active RTs).
SELECT
    ac."Record ID" AS client_id,
    ac."Company name" AS client_name,
    rta."Contractor ID" AS contractor_id,
    rta."RT Name" AS rt_name,
    rta."Role Title (External)" AS role_title,
    rta."Client/RT Start Date" AS start_date,
    CAST(rta."RS - Base Rate" AS REAL) AS rs_base_rate,
    CAST(rta."Current Rate with Client" AS REAL) AS current_rate_with_client,
    CAST(rta."Partner Rate" AS REAL) AS partner_rate,
    CAST(rta."Fixed Rate" AS REAL) AS fixed_rate
FROM rt_assignments rta
JOIN active_clients ac ON ac."Record ID" = rta."Associated Company IDs"
WHERE rta."RT Status" LIKE 'Active%' AND rta."Contractor ID" IS NOT NULL
ORDER BY ac."Company name", rta."RT Name";
