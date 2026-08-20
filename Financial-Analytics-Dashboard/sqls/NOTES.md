# Financial-Analytics-Dashboard — SQL Backfill Notes

These `.sql` files reproduce the 9 existing charts in
`FinancialHealth&RevenueAnalytics.html` from `Rocket_Station/data/rocket_station.sqlite`,
so the dashboard's numbers are now auditable and refreshable instead of static.

## What was verified

Chart 1's hardcoded KPI cards were cross-checked against real `Invoices.csv` data and
matched almost exactly (Jun 2026: $2,436,189.73 vs hardcoded $2,436,190; Jul 2026:
$2,054,747.96 vs $2,054,748; Aug 2026 MTD: $500.00 exact). **The dashboard's original
numbers are real, not fabricated** — the gap was that the SQL behind them was never
saved. These files close that gap for chart 1 and charts 4-9.

## Charts 2 & 3 — correction

**Update: these ARE reproducible — an earlier version of this note said they weren't.**
That was wrong: I'd only checked `invoices."Payment Collection Option"` /
`"Invoice Tool Source"` (both empty) and missed that the real field is
**`active_clients."Payment Method"`** (values: `NMI - ACH`, `NMI - Credit Card`,
`Client Invoice`, populated for 348 of 495 clients). `chart2_...sql` and
`chart3_...sql` use it and land within ~0.1% of the dashboard's original hardcoded
numbers for the same billing cycles.

I found this field by reading a set of pre-existing `.sql` files that appeared in
this same folder (`1_Complete_Executive_KPI_Scorecard.sql`,
`2_Cleared_vs_Pending_Revenue_by_Payment_Type.sql`, etc. — named after the chart
images in `assets/`) which I did not create. Their provenance is unclear to me —
they weren't there when this backfill work started, and I don't know if they came
from the original dashboard build, a sync from elsewhere, or something else. They
look correct and more careful than my own first pass in one respect (they resolve
`invoices."Associated Company IDs"` by taking the first ID when it holds more than
one, comma/semicolon-separated — a case that affects 4 of 4944 invoices, immaterial
to the totals but more correct). **Worth confirming with whoever has access to this
workspace where those files came from**, since I'm working from what's on disk and
can't otherwise verify it.

## A data-correctness bug we hit and worked around

While validating these queries, several `JOIN ... GROUP BY <text column from the
joined table>` queries (industry, Client Health Score, company-size bucket) returned
silently wrong results under the older SQLite engine bundled with this machine's
Python (3.35.5) — a single group (e.g. "Property Management") was split into a dozen
identical-looking groups, inflating the apparent number of categories and quietly
double/triple counting revenue. It reproduces even with `PRAGMA integrity_check` clean
and no automatic indexes involved, and disappears once the join is materialized before
grouping — consistent with a known class of SQLite query-flattening optimizer bugs
from that era, since fixed in later SQLite releases.

**Workaround used throughout these queries**: the join is wrapped in a subquery ending
`LIMIT -1 OFFSET 0`, a standard SQLite trick that blocks the query planner from
flattening the subquery back into the outer GROUP BY, forcing correct materialization
first. Every number in this dashboard's backfill and in the new report catalog was
re-validated with this workaround in place. If DBeaver's SQLite driver is a modern
version (very likely), the workaround is harmless — it just adds a no-op row limit.
