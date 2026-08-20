# Client → RT → Hours Drill-down Dashboard

**What this answers:** starting from a business category, drill down through
clients, into roles/RTs, into an individual RT's hours and estimated $ — an
exploratory tool rather than a fixed report. Split out into its own dashboard
(previously lived inside `In-Progress/Workforce-Deployment-Coverage-Dashboard`)
since it spans category, staffing, and hours/billing territory rather than
fitting cleanly into any one catalog category.

**Status:** interactive HTML built. The treemap-click-to-correct-client bug
(Testing status #6-#15) is fixed and user-confirmed, and the **Actual Billing**
summary strip (real invoiced revenue from `Invoices.csv`) is confirmed working
and well-received. Called "the final version" once, then reopened for a
**rate field correction** (Est. Revenue/Est. Cost formulas — see below) after
an internal review of RS's own field definitions. Still awaiting confirmation
on: the role-hover popup, the rebucketed Client Tier grouping, the Sankey
column alignment fix, the client info header, the client search box, Missed
Shifts, the rate field correction, and the newest addition — the **Parent
Company treemap grouping**.

## Folders

- `data/` — source CSVs: `active_clients.csv`, `RTAssignments.csv`,
  `RemoteTeammates.csv`, `rt_logins_2026-07-26_2026-08-10.csv`, `Invoices.csv`,
  `rt__missed_logins_2026-07-26_2026-08-10.csv`
- `sqls/` — the 6 queries behind the report, runnable as-is in DBeaver against
  `Rocket_Station/data/rocket_station.sqlite`
- `assets/` — `drilldown_data.js`, the embedded dataset the report reads from.
  Regenerate with `python Rocket_Station/data/extract_drilldown_data.py` if the
  source CSVs change.

## The report

Open [`ClientToRTDrilldown.html`](ClientToRTDrilldown.html) directly in a browser
(double-click it, or right-click → Open with, from VS Code's Explorer). Self
contained, no server needed.

**Flow:**
1. **Treemap** of clients (tile size = active RT headcount) — stays visible
   the whole time, it's never replaced by anything. Three grouping modes,
   left to right: **Business Industry** (the default/focus), **Parent
   Company** (see below), **Client Tier** (buckets: `15+`, `10 to 15`,
   `5 to 10`, `3 to 4`, `1 to 2`, `.5`, `Unclassified`, computed from active
   RT headcount directly, not the source CRM's own "Tier" field, whose
   boundaries were different: 15+/8-14/4-7/2-3/.5-1 — clients the CRM left
   with no Tier at all stay `Unclassified` regardless of headcount). Next to
   the grouping toggle, a **"Find a client" search box** offers a typeahead
   over all 326 client names (top 10 matches, ranked by active RT headcount)
   — picking one opens its Sankey directly, the same as clicking its tile,
   for when scanning 100+ tiles by eye isn't practical, and it isn't affected
   by which grouping mode is currently active.

   **Parent Company grouping** (newest addition, not yet tested): unlike
   Industry/Tier, which show every client (with an `Unclassified` fallback
   for the field being empty), this mode shows **only** the 53 clients (of
   326 with active RTs) that are part of a multi-entity parent/child company
   group in `active_clients."Child Company IDs"` / `"Parent Company IDs"` -
   everyone else is excluded entirely rather than bucketed, since a client
   with no parent/child relationship has nothing to show here. Grouped by
   parent company name (14 groups render - a 15th family, Freedom Family
   Investments, has 0 members with any active RTs, so it produces no tiles).
   The parent company's own tile is included as a member of its own family
   (not just a header for its children) whenever it has active RTs itself -
   e.g. the "Tricon" group contains a "Tricon" tile plus its 13 active
   sub-account tiles side by side, which can look like the group header and
   a tile repeat the same name; this is expected, not a bug, since the
   parent genuinely is one of its own family's members.

   Clicking any member tile here uses the **exact same click-to-Sankey
   mechanism** as Industry/Tier (`CLIENT_ID_BY_NAME`, built once from the
   full client list regardless of which grouping is active) - no new code
   path, so none of the click-resolution bugs from earlier rounds are back
   in play. Validated before shipping: some parent companies list child IDs
   that don't have their own `active_clients` row at all (4 of 46 referenced
   child IDs across all 15 families) - those simply can't have a tile since
   there's no client record to tag, confirmed this doesn't silently drop
   *tileable* clients, only ones that were never tileable to begin with.

   **Tile sizing in this mode is different on purpose**: Industry and Tier
   size tiles by active RT headcount, same as always - but here, tile/group
   size is driven by **family member count** instead (a constant `1` per
   tile, so a family's total on-screen area = how many members it has, not
   how many RTs are staffed across it), per explicit request. This meant
   `key` in the Chart.js config now switches between `active_rt_count` and
   a new `member_weight` field depending on the active grouping - which
   reopened the exact bug class rounds 9-15 spent so long chasing (chartjs-
   chart-treemap only retains fields referenced by `groups`/`key` in its
   internal per-tile `_data`, silently dropping everything else). Caught
   this *before* shipping, not after: `active_rt_count` is still shown in
   every tile's label and tooltip regardless of grouping, so switching `key`
   away from it in Parent Company mode would have made that number quietly
   disappear there specifically. Fixed generally, not with a one-off patch -
   a new `CLIENT_BY_NAME` lookup (same pattern as the existing
   `CLIENT_ID_BY_NAME` fix) resolves `active_rt_count` from the source data
   directly, bypassing the plugin's internal reconstruction entirely, so
   this stays correct no matter what `key` ends up being in any future mode.
2. **Click a client tile (or a search result)** → a Sankey panel appears
   *below* the treemap, rooted at that one client, with **two tabs** covering
   the same Roles/RTs breakdown from two different angles. Click a different
   tile any time to swap which client the panel shows (always reopens on the
   Roster Summary tab). Right under the client name:
   - A **client info strip** — Industry, Tier (the same recomputed bucket used
     for grouping, not the raw CRM field), Client Health Score (color-coded
     Green/Amber/Red/Unclassified badge), and Annual Revenue. Doesn't change
     with tab or date filter — it's identity, not activity. Annual Revenue is
     only populated for about 38% of clients in this data (190 of 495) and
     shows `—` otherwise, same for Health Score (274 of 495 populated).
   - An **Actual Billing** strip shows real invoiced revenue from
     `Invoices.csv` (Paid Revenue, Open Balance, invoice counts) - this is a
     genuine billed number, not the hours × rate estimate used elsewhere on
     this page:
   - **Roster Summary** — flow width = active RT headcount, no date range.
     Answers "who's assigned." Hovering an RT shows only role, start date, and
     both hourly rates. The billing strip shows **all invoices on file** for
     the client (all-time), since headcount doesn't have a date dimension to
     match against.
   - **Hours & Billing Detail** — flow width = hours actually worked in the
     date range selected in this tab (defaults to the full 15 days). Answers
     "where did the hours/$ go." Hovering an RT shows everything: role, start
     date, rates, Total Hours, Overtime, Est. Revenue, Est. Cost for that range,
     plus the login heatmap. Changing the date range redraws the diagram, the
     billing strip, and any open tooltip's numbers immediately — an RT with 0
     hours in a narrow range still appears (as a hairline flow) rather than
     vanishing, so the roster stays visible even when nobody worked in that
     window. The billing strip narrows to **invoices dated within that same
     range** — checked against real data before building this: 313 of 340
     invoiced clients have at least one invoice dated in the default 15-day
     window, so this isn't usually a near-empty view, though a client with
     invoices only outside the selected range will correctly show "No invoices
     dated ... for this client" rather than a confusing $0.
3. **Click a role node** (either tab) → *that role's* RTs appear (Role → RTs) —
   other roles stay collapsed, so the diagram only ever shows what you've
   actually asked to see. Click again to collapse. (Roles are skipped entirely,
   straight to Client → RTs, when distinct role count is ≥70% of that client's
   RT count — calibrated against the real data, where clients either cluster
   tightly (ratios 0.05–0.32) or are fully 1-to-1 (ratio 1.00), with a clean gap
   between the two groups.) Columns are fixed by distance from the client
   (Client → Roles → RTs, always in that order left to right) rather than
   d3-sankey's default of pushing "no children yet" nodes as far right as
   possible — the default made an un-expanded role's column drift depending on
   what else was expanded, which is what was making expanded RTs look mixed in
   with the remaining roles.
4. **Hover any RT node** → tooltip content depends on the active tab, as
   described above. The Hours & Billing Detail heatmap is a compact strip
   instead of a bar/line chart, since daily hours are nearly identical most
   days for a given RT and a full trend chart wastes space showing that
   sameness; the heatmap makes the few days that differ visually obvious
   instead. In that same tab, a **Missed Shifts** count (red when > 0) sits
   alongside Total Hours/Overtime/Est. Revenue/Est. Cost, and the heatmap
   marks each no-show day with a red ring — see "Missed Shifts" below.
5. **Hover a role node** (not an RT) → a *rolled-up* version of the same
   tooltip, covering every RT under that role. Roster Summary shows the RT
   count, the range of their start dates, and the **average** RS Base Rate and
   Client Rate (rates don't have a date dimension, so averaging is the natural
   "same fields as an RT, rolled up" reading). Hours & Billing Detail shows the
   **sum** — not average — of Total Hours, Overtime, Est. Revenue, Est. Cost,
   and Missed Shifts across those RTs for the selected date range, since these
   are all additive, not something you'd average across people.

**Why client-rooted, and a role/RT cap**: the first version opened the *whole
industry* as a Sankey (Industry → every client in it) before drilling into a
client, and Property Management alone has 100+ clients — Google's Sankey
renderer doesn't paginate or scroll, it just divides the available height by
however many nodes you hand it, and once that stops fitting it throws `<rect>
attribute height: A negative value is not valid` and renders a cluttered,
overlapping mess (this actually happened). Starting directly from the clicked
client removes that whole layer — a client's own Roles/RTs list is naturally
much smaller. A defensive 15-node cap (with a "+N more..." node) is still kept
on the Roles and RTs levels in case some client turns out to have an unusually
large roster.

Est. Revenue = hours × Partner Rate; Est. Cost = hours × Current Rate with
Client (falling back to RS Base Rate when unset) — both are estimates, since
invoices are billed at the client level, not per RT, so there's no real
per-RT dollar figure in the source data. See "Rate field correction" below
for how these formulas changed from the original build and why.

## Data-quality note baked into this report

`role_title` uses `RTAssignments."Role Title (External)"`, not `"Remote Teammate
Title"` — the latter is always just `"<RT Name> - <Contractor ID>"`, 100% unique
per row, so it's useless for the Roles-vs-RTs grouping decision above. This was
caught and fixed during this report's build (`extract_drilldown_data.py` and
`sqls/drilldown_2_active_rts_per_client.sql` both have the correction, with the
reasoning in their comments).

## Sharing this with teammates

This needs to work identically on other people's machines too (not just yours),
so keep two things in mind:

- **Share the whole `Client-RT-Drilldown-Dashboard` folder**, not just the
  `.html` file on its own — it loads its data from `assets/drilldown_data.js`
  next to it via a relative path, so the two have to travel together (zip the
  folder, or share it via a shared drive/repo).
- **Whoever opens it needs internet access** — Tailwind, Chart.js, the treemap
  plugin, and D3 all load from public CDNs at open time rather than being
  bundled into the file. No login or account needed for any of them, just a
  live connection.

Beyond that, it opens the same way for anyone: double-click the `.html` file, no
install and no server required.

## Testing status — please read before relying on this

This environment has no browser, so nothing here has been visually confirmed by
me directly — testing has happened in your browser, and real bugs have come back
from every round so far:

1. **Treemap clicks did nothing**: a Chart.js/treemap-plugin version mismatch
   broke click handling while still rendering tiles fine. Fixed by pinning to a
   known-compatible pair (Chart.js 4.4.4 + chartjs-chart-treemap 3.1.0).
2. **Sankey view was an unreadable cluttered fan, with console errors**
   (`<rect> attribute height: A negative value is not valid`): the industry-level
   Sankey (Industry → every client, 100+ for some industries) overloaded Google's
   Sankey renderer. Fixed by removing that level entirely — the Sankey is now
   rooted at the clicked client, see the redesign above.
3. **Treemap hover tooltip showed a bogus "undefined (Property Management)"
   line**: the treemap plugin creates a synthetic aggregate record for each
   industry's header band, and the first fix attempt checked the wrong field
   (`client_id`, which turned out not to survive the plugin's internal data
   handling at all, breaking every tile's tooltip, not just headers). Fixed by
   checking `client_name` instead — confirmed correct by direct evidence, not
   another guess: the original bug report's "undefined" text was itself
   `client_name` printing as undefined, so that's the field known to actually
   distinguish a header from a real tile.
4. **Clicking a role node in the Sankey did nothing, with no console error, and
   a console warning about `file:` URLs being treated as unique security
   origins**: that warning was the real cause, and it wasn't fixable by tweaking
   event-handling code — Google's Sankey chart needs an internal iframe to load,
   and browsers block that entirely for pages opened via `file://` (every local
   file is its own isolated origin, so the iframe can never be treated as
   same-origin, even though it points at the exact same file). This is a hard
   limitation of Google Charts, not a bug to patch around, and it would have hit
   every teammate the same way, not just this machine. **Fixed by switching the
   whole Sankey away from Google Charts to D3 + d3-sankey**, which draws plain
   SVG with no iframe involved — the same approach every other chart in this
   project already uses successfully under `file://`. Click and hover are now
   bound directly to each SVG element via D3's native event handling, which also
   removes the uncertainty around Google's undocumented node-selection format
   that earlier fix attempts were guessing at.

5. **Even after switching to D3, clicking a client tile still did nothing at
   all** - not even the Sankey panel's header/close-button appearing, which
   should have shown regardless of whether the chart itself drew successfully.
   That "nothing at all, no banner either" symptom means something is failing
   silently upstream of the parts that already have error handling - most
   likely the D3/d3-sankey scripts themselves 404ing (the exact `/dist/*.min.js`
   filenames used weren't independently verified to exist) with no visible sign
   since a failed `<script>` tag doesn't raise a JS error on its own.
   **This exact round's fix is diagnostic, not confirmed** - the script tags
   now use jsdelivr's auto-resolved package entry point instead of a guessed
   filename (removing one likely failure point), plus two new safety nets: an
   `onerror` on those two script tags that shows an immediate red banner at the
   top of the page if either fails to load, and a global
   `window.addEventListener('error', ...)` catch-all that surfaces *any*
   uncaught error on the page as a visible banner instead of only in the
   console. If the underlying cause turns out to be something else entirely,
   this round should at least surface it visibly instead of staying silent.

6. **Still nothing after the D3 switch, and no banner appeared either** - which
   ruled out the diagnostic theory above (a script load failure would have hit
   the new banner). The console showed `[treemap click] elements: (2)` on every
   click - Chart.js is consistently finding **two** overlapping hits at the
   click point, almost certainly the industry header band stacked on top of the
   client tile beneath it. The click handler was taking `elements[0]`
   unconditionally, so depending on which of the two came first, it could
   silently grab the header (no `client_id`) exactly as often as the real tile
   - and the stricter `client_id` check added a few rounds ago (to fix the
   tooltip bug) meant a header match now fails silently instead of doing
   anything, whereas the old looser check would have "worked" by accident since
   headers and tiles both carry `group_label`. Fixed by scanning **every**
   returned element (and every geometry-fallback candidate) for one that
   actually has `client_id`, instead of trusting array order.

7. **Clicking Frontsteps opened a Sankey rooted at "Folio Association
   Management" instead** - the Sankey rendered fine at this point (previous
   round's fix worked), but for the wrong client. Root cause: Chart.js's
   `elements` array (its own "nearest matches" interaction-mode result) can
   include a *sibling* tile near a boundary, not just the header/leaf pair at
   the exact point - so scanning that array for a `client_id` match (the round
   6 fix) could still land on the wrong tile. Fixed by dropping `elements`
   entirely and using **only** exact point-in-rectangle geometry hit-testing,
   which can't have that ambiguity between siblings (their rectangles never
   overlap each other - only a tile and its own parent header band do, which
   the `client_id` check still resolves correctly).
8. **RT tooltip didn't make clear what date range the Total Hours/Overtime/Est.
   Revenue/Est. Cost numbers covered** - it showed the full 15-day window label
   under the heatmap, but that label was never actually about the numbers above
   it (which use the date filter at the top of the page, defaulting to the full
   window but changeable). Fixed by adding an explicit "Hours & $ for `<from>`
   → `<to>`:" line directly above those four numbers.
9. **Checked a specific RT's data (Arvil Kurt Jacob Medenilla) the user
   suspected the heatmap had wrong** - turned out to be a side effect of bug 7
   above: they'd been looking at Folio Association Management (via the
   mis-clicked tile), not Frontsteps, and "Customer Service Support" was that
   RT's *role*, not a client. On the heatmap itself: this RT's real
   `rt_logins` rows are all tagged `Login Status = "Out of Shift"`, but the
   actual First Login/Last Logout timestamps show genuine ~9-hour sessions each
   of those days (06:5x AM–4:0x/1x PM) against a *scheduled* shift of
   08:00–17:00 - so "Out of Shift" here means "logged in outside their assigned
   shift window," not "didn't work." The heatmap is reading the source data
   correctly; the color legend and the underlying data agree. Separately: days
   with no `rt_logins` row at all correctly render as blank/faint, and this
   RT's `rt__missed_logins` rows (genuine no-shows) aren't counted as hours
   either. If a specific date still looks wrong after re-checking against the
   correct client, flag that exact date and I'll trace it in the raw CSV.
10. **Long client names got cut off in big tiles** (e.g. "Sentry Management,
    Inc. - Financial Reporting") even though the tile had visible room. Added
    word-wrapping onto up to 2 lines, using the tile's rendered pixel width
    when chartjs-chart-treemap exposes it, falling back to a fixed-width
    estimate otherwise.
11. **The top date filter didn't visibly do anything to the heatmap or the
    Sankey diagram itself** - by design, at the time: it only ever affected the
    numbers inside the RT hover tooltip, and even that had no visible feedback
    until you hovered an RT again after clicking Apply. Rather than patch that
    single gap, this was restructured into the **Roster Summary / Hours &
    Billing Detail** tab split described above - the date filter now lives
    inside the Detail tab specifically, and changing it redraws the Sankey's
    flow widths (now hours-based in that tab) immediately, not just the
    tooltip. The Summary tab intentionally has no date filter at all, since its
    flow widths (headcount) don't have a date dimension.

12. **Clicking "RENOSY by Renters Warehouse" opened a Sankey rooted at
    "Highmark Residential" instead** - a different bug than #7, even though it
    looked identical from the outside. This time the *rectangle* found at the
    click point was provably correct (visually confirmed against the
    screenshot), but the code then looked up `treeData[i]` using that same
    numeric index `i` from Chart.js's internal element array - silently
    assuming the two arrays are ordered the same way. They aren't:
    chartjs-chart-treemap groups and reorders elements internally for layout
    (by industry, then client), so index `i` means a different tile in each
    array. Fixed by never cross-referencing a second array by index again -
    once geometry finds the right rectangle, its own bound data is read
    directly off that same element (`el.$context.raw._data`) instead.

13. **Still nothing on click after #12's fix** - console showed
    `matched: null` and `only header band(s) matched`, meaning `el.$context.raw`
    (the #12 fix's own data-access method) wasn't returning usable data even
    though the right rectangle was being found. `$context` turns out not to be
    reliably populated on treemap elements outside of Chart.js's own internal
    tooltip code path. Replaced it with the one access pattern Chart.js
    actually *guarantees*: every dataset's rendered elements
    (`chart.getDatasetMeta(d).data`) are always parallel, index-for-index, to
    that same dataset's own `data` array (`chart.data.datasets[d].data`) - true
    for every chart type by construction, including custom ones like treemap.
    So the click handler now finds the right rectangle (via
    `getElementsAtEventForMode(evt, 'point', {intersect:true})`, with a manual
    geometry loop as a fallback), then reads `chart.data.datasets[0].data[i]`
    at that same index - never `treeData[i]`, never `el.$context`.

14. **#13's fix also resulted in nothing at all** (`matched: null`, no console
    error). At this point the user pointed out something that reframed the
    whole debugging trail: clicking *did* work, several rounds ago, before any
    of the client-mismatch fixes (#7 onward) - it just occasionally opened the
    wrong client. That single fact rules out every theory tried since: if
    `elements` + `el.element.$context.raw._data` (the original mechanism, used
    up through #7) never reliably returned real data, clicking couldn't have
    worked at all back then, wrong client or not. So `$context` access via
    `elements` was never the problem - #9's own diagnosis of it was wrong. The
    actual, only real bug was always #1: Chart.js's default interaction mode
    lets `elements` match a tile *near* the click point ("nearest"), not only a
    tile the point is exactly inside, which is how a click on RENOSY's tile
    could resolve to Highmark Residential's. Fixed by addressing that directly
    at the source - `interaction: { mode: 'point', intersect: true }` added to
    the chart's own options, forcing `elements` to only ever contain exact
    containment matches - and reverting `onClick` back to the original,
    proven-working extraction (`elements` + `el.element.$context.raw._data`),
    undoing the index-based detours from #12 and #13 entirely.

15. **#14's fix didn't hold either** - `interaction: {mode:'point'}` correctly
    narrowed the hit-test to 2 elements, but `el.element.$context.raw._data`
    still had no `client_id` on either of them. Added diagnostics instead of
    another theory, and the user's console output finally showed the real
    answer: element[1]'s reconstructed `_data` (the genuine "Sentry Management,
    Inc. - Financial Reporting" tile) had `dataKeys: ["children",
    "active_rt_count", "client_name", "label", "path", "group_label", "_idx"]`
    - **`client_id` was never in that list at all**, on any attempt, in any of
    rounds 9-14. **Root cause, finally confirmed by evidence rather than
    theory**: chartjs-chart-treemap reconstructs each element's `_data`
    internally using only the fields referenced by the dataset's `groups`
    (`group_label`, `client_name`) and `key` (`active_rt_count`), plus its own
    bookkeeping - `client_id`, an extra field this page added that isn't
    referenced anywhere in the chart config, was silently dropped every time,
    regardless of which JS property path was used to reach `_data`. That's why
    every fix from #9 onward failed the same way no matter how it accessed the
    data - the data itself never had `client_id` to find.
    **Actual fix**: since `client_name` reliably does survive, a
    `CLIENT_ID_BY_NAME` lookup map is now built once, straight from the source
    data (`DRILLDOWN_DATA.clients`), and the click handler resolves the real
    `client_id` through that map instead of expecting the plugin to hand it
    back. Checked against the real data: all 495 active clients have unique
    company names, so this lookup can't collide.

**#15 is confirmed working** - the user tested it directly ("Super this
worked"). The role-hover popup and rebucketed Client Tier grouping (both
introduced the same round as #15) haven't been separately confirmed yet.

## Actual Billing summary strip (confirmed working - "Good Stats this really good")

Added after the click fix, at the user's request, to answer "how does the
hours-based estimate compare to what we actually billed this client." Real
invoiced revenue from `Invoices.csv`, shown in the Sankey panel header
(`sqls/drilldown_4_invoices_per_client.sql`):

- **Roster Summary tab**: all invoices on file for the client, all-time -
  matches that tab's "no date range" character (headcount doesn't have a date
  dimension either).
- **Hours & Billing Detail tab**: invoices dated within the same From/To range
  as the RT hours - this was a deliberate choice over filtering to the exact
  same window everywhere, since RT hours only span a fixed 15-day window while
  invoices span many months on their own billing-cycle cadence. Checked
  against real data before building this: 313 of the 340 invoiced clients have
  at least one invoice dated in the default 15-day window, so this isn't
  usually a near-empty view - a client with zero invoices in the selected
  range shows a clear "No invoices dated ... for this client" message instead
  of a bare $0 that could read as broken.

Spot-checked one client's numbers against report 5.1 (Blended Client
Scorecard, a completely different query path) before shipping: Sentry
Management, Inc. - Financial Reporting's all-time paid revenue matched exactly
($1,090,625.83), so the underlying join is trusted.

## Sankey column alignment fix (not yet tested)

User reported expanded roles' RTs visually mixing in with non-expanded roles.
Root cause: d3-sankey's default `nodeAlign` (`sankeyJustify`) pushes any node
with no *current* outgoing links as far right as possible, so a not-yet-
expanded role and an expanded role's RTs both count as "sinks" and compete for
the same rightmost column - position drifted based on what happened to be
expanded. Fixed with `.nodeAlign(d3.sankeyLeft)`, which instead places every
node by distance from the client root: Client always column 0, every role
always column 1, every RT always column 2, regardless of expand state.

## Client info header + client search box (newest additions, not yet tested)

Two more from the same "what else would help" conversation:

- **Client info strip**, in the Sankey panel header alongside Actual Billing:
  Industry, Tier (the recomputed bucket, not the raw CRM field, for
  consistency with the treemap's own grouping), Client Health Score (colored
  badge), Annual Revenue. Sourced from `active_clients` via the same query as
  the treemap tiles (`sqls/drilldown_1_clients_with_active_rts.sql`, now also
  pulling `Client Health Score` and `Annual Revenue`). Checked population
  before shipping: Health Score is set for 274 of 495 clients, Annual Revenue
  for only 190 of 495 - both show `—` rather than blank/misleading zeros when
  absent.
- **Client search box** ("Find a client"), next to the Group-by toggle -
  typeahead over all 326 client names, top 10 matches ranked by active RT
  headcount, click a result to open its Sankey exactly like clicking its tile.
  Exists because scanning 100+ tiles in a busy industry to find one specific
  client isn't practical.

## Missed Shifts — reliability signal (newest addition, not yet tested)

Until now this report only answered "how much did this RT work and bill" —
`rt__missed_logins.csv` (no-shows, same 15-day window as `rt_logins.csv`) was
never used anywhere, even though reliability (does this person show up) is a
different question from productivity (how many hours when they do). An RT can
carry a solid hours total while still missing scheduled shifts that got
absorbed elsewhere, and that gap was invisible in the old view.

Surfaced in the **Hours & Billing Detail** tab only (missed shifts are
inherently date-scoped, same reasoning as why Total Hours/Overtime/Est.
Revenue/Est. Cost live there and not in Roster Summary):

- RT hover: a **Shifts: N worked / M missed (T total, R% missed)** line for
  the selected date range, alongside the existing hours/$ stats
  (`sqls/drilldown_5_missed_logins_per_rt.sql`). A bare missed count doesn't
  say much on its own — "worked" (one row per logged session in
  `rt_logins`, not one per calendar day; RTs don't all have a daily cadence)
  is the denominator that turns it into a rate. Checked against real data:
  74 active RTs in this dataset have 0 worked shifts against a fully missed
  schedule (100% miss rate) — a genuinely different situation from "missed 2
  of 40," which the count alone couldn't distinguish.
- Role hover: the same worked/missed/total, **consolidated** (summed) across
  every RT in that role, then the rate recomputed off the summed totals (not
  an average of each RT's own rate) — same summed-not-averaged treatment as
  the other Detail-tab stats.
- The login heatmap now rings each missed-shift day in red (always shown
  across the full 15-day window, like the rest of the heatmap, independent of
  the date filter) so worked days and no-show days read off the same strip
  instead of a bare number needing a separate lookup.

Checked against the real data before building this: all 1,200 contractor IDs
with at least one missed shift are active RTs already in this report's
roster (no orphaned IDs to silently drop), and the missed-logins window
matches `rt_logins` exactly (2026-07-26 → 2026-08-10).

## Rate field correction — Est. Revenue and Est. Cost formulas changed

After this dashboard was called "the final version," an internal review of
RS's own rate-field definitions revealed that **the original Est. Revenue
formula was using the wrong field**, and the fix changes visible $ figures
dashboard-wide by roughly 2x on average. Kept here in detail since it's the
single biggest correction made to this report's numbers after ship.

**What was wrong**: the field `Current Rate with Client` sounds like a client
billing rate, but per RS's own definitions it is not one - it's the RT's
current *pay* rate (RS Base Rate plus any client-funded raise). Confirmed
against real data, not just the field name: zero active RTs have `Current
Rate with Client < RS Base Rate` (consistent with "starting rate plus raises
only"), and where both `Current Rate with Client` and the real billing field
`Partner Rate` are populated on the same row (1,211 of 1,376 active RTs),
`Partner Rate` averages **2.21x** `Current Rate with Client` (range 0-3.5x) -
far too large a gap to be the same number measured two ways. The original
build (see "Actual Billing summary strip" above) had already estimated
Est. Revenue as `hours × Current Rate with Client`, which was therefore
computing something close to RT pay cost, not client billing.

**Validated fix, not just a theory**: tested both formulas against real
invoiced revenue for Sentry Management, Inc. - Financial Reporting (110
active RTs) over the same 15-day window used everywhere else in this
dashboard:

| Formula | Est. Revenue |
|---|---|
| Old (hours × Current Rate with Client) | $29,961 |
| New (hours × Partner Rate) | $65,847 |
| Actual invoiced revenue (same window, from `Invoices.csv`) | $83,300 |

The old formula captured ~36% of actual billed revenue; the new one gets to
~79% (still not exact - the invoice likely also includes admin fees / credit
card surcharges on top of RT pay lines, per the `Associated Line item` field
documented in the data dictionary).

**Two complications found and resolved** (per internal review's decisions):

1. **Fixed Rate clients** (15 of 1,376 active RTs, ~1.1% - all Brookfield
   Properties sub-accounts, all billed a flat `$1,900/mo` or `$950/mo` per
   RT instead of hourly): these RTs are **excluded from Est. Revenue
   entirely for now**, shown as "Fixed Rate (excluded)" with a note, rather
   than computing a misleading `hours × Partner Rate` (which would show ~$0,
   since most of these RTs also have `Partner Rate = 0`).
2. **Zero/missing Partner Rate on non-fixed-rate clients too** (e.g. all 5
   active RTs at Guesty Inc, on `Invoice Type = "Special Invoice"`, have
   `Partner Rate = 0` despite a normal hourly `Current Rate with Client`) -
   these show **"—"** instead of a false $0, since $0 here means "billed
   another way," not "billed nothing."

**Formula changes**:
- Est. Revenue: `hours × Current Rate with Client` → `hours × Partner Rate`
  (excluded/"—" per the two rules above).
- Est. Cost: `hours × RS Base Rate` → `hours × Current Rate with Client`
  (falling back to RS Base Rate when Current Rate with Client is unset, ~1.7%
  of active RTs) - per internal review's decision to use the more current
  cost figure when a client-funded raise applies, rather than the static
  original rate.

**UI changes**: RT and role tooltips (both tabs) now show 3 rate fields
instead of 2 - RS Base Rate, `Current Rate with Client` (relabeled from
"Client Rate" to avoid the exact confusion that caused this bug), and
`Partner Rate` - plus a Fixed Rate line when present. Role-level rollups
(`computeRoleAggregate`) average Partner Rate across a role's RTs excluding
fixed-rate/unavailable ones (same "—" treatment as the individual RT view),
and the Hours & Billing Detail tab's summed Est. Revenue shows a note when
some RTs in a role were excluded ("Est. Revenue excludes 2 fixed-rate +
1 rate-unavailable RTs (of 12 in this role)"). `Client Base Rate` remains
unused - still 0% populated among active RTs, confirmed again during this
investigation.

**Display labels, one round later**: the relabeling above still wasn't
enough - "Current Rate with Client" still *sounds* like a billing rate even
though it isn't one, which is the exact confusion this whole correction was
about. Final on-screen wording (source CRM field names unchanged, this is
display text only): **RS Base Rate** stays as-is; `Current Rate with Client`
displays as **"RS Current Rate"** (pairs with RS Base Rate - both visibly
cost-side, one's the floor, one's current); `Partner Rate` displays as
**"Billed Rate"** (unambiguously the billing-side number, in its own visual
family from the two RS-prefixed cost fields). Applied everywhere these
fields appear: both tooltip tabs, the role-level "Avg" rollups, and the
on-page disclaimer banner (which also now states the source field name in
parentheses next to each display label, since that banner doubles as
documentation).

`sqls/drilldown_2_active_rts_per_client.sql` and `extract_drilldown_data.py`
now pull `Partner Rate` and `Fixed Rate` alongside the existing two rate
fields. Not yet re-tested by the user in a browser since this change.

Full detail on the underlying data: see the master
[Analytics_Requirements_and_Report_Catalog.md](../../docs/Analytics_Requirements_and_Report_Catalog.md)
and [Data_Dictionary.md](../../docs/Data_Dictionary.md).
