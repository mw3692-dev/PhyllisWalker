-- Client → RT Drill-down, query 1 of 6: clients with active RTs, by industry
-- and tier, plus context fields for the client info header.
-- Powers the treemap tiles (tile size = active_rt_count) and the Industry /
-- Tier / Health / Annual Revenue strip shown when a client is selected.
SELECT client_id, client_name, industry, tier, health_score, annual_revenue,
       COUNT(*) AS active_rt_count
FROM (
    SELECT
        ac."Record ID" AS client_id,
        ac."Company name" AS client_name,
        COALESCE(ac."Business Industry", 'Unclassified') AS industry,
        COALESCE(ac."Tier", 'Unclassified') AS tier,
        ac."Client Health Score" AS health_score,
        CAST(ac."Annual Revenue" AS REAL) AS annual_revenue
    FROM rt_assignments rta
    JOIN active_clients ac ON ac."Record ID" = rta."Associated Company IDs"
    WHERE rta."RT Status" LIKE 'Active%'
    LIMIT -1 OFFSET 0
)
GROUP BY client_id, client_name, industry, tier, health_score, annual_revenue
ORDER BY active_rt_count DESC;
