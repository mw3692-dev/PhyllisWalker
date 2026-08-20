-- Client → RT Drill-down, query 5 of 6: missed shifts per RT (15-day window)
-- Powers the "Missed Shifts" reliability stat shown in the RT/role hover in the
-- Hours & Billing Detail tab, plus the red-ring markers on the login heatmap.
-- One row per no-show (presence in this table = a missed shift; there is no
-- separate "reason" or "excused" flag in the source data).
SELECT
    "Contractor ID" AS contractor_id,
    "Date" AS missed_date
FROM rt_missed_logins
ORDER BY "Contractor ID", "Date";
