-- Client → RT Drill-down, query 3 of 6: daily logged hours per RT (15-day window)
-- Powers the hours/$ chart shown after clicking an RT. Est. Revenue/Cost are
-- computed client-side as hours * client_rate / hours * rs_base_rate from query 2,
-- since there is no per-RT dollar amount in the source data (invoices are billed
-- at the client level only).
SELECT
    "Contractor ID" AS contractor_id,
    "ShiftDate" AS shift_date,
    CAST("Regular Hours" AS REAL) AS regular_hours,
    CAST("Overtime Hours" AS REAL) AS overtime_hours
FROM rt_logins
ORDER BY "Contractor ID", "ShiftDate";
