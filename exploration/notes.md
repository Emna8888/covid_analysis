# Data Exploration — corona_timeseries_monde

## Dataset overview
- **Rows:** 248,348
- **Columns:** date, annee, mois, trimestre, semaine_iso, pays, nouveaux_cas, nouveaux_deces, cas_cumules, deces_cumules, cas_hebdomadaires, deces_hebdomadaires, cas_bihebdomadaires, deces_bihebdomadaires
- **Date format:** jj/mm/aa, consistent across the dataset. `annee` and `mois` columns duplicate part of the date (without day-level granularity), useful for a future Dim_Date.

## Grain check (Afghanistan)
- Tracking period: 24/02/2020 → 09/03/2023
- Represented by 1,111 rows → matches 1,111 days tracked, confirming the grain is **one row per country per day**.
- Same check on "Africa": 1,120 rows = 1,120 days tracked (13/02/2020 → 09/03/2023) — consistent daily grain.

## Missing values vs. zero (important distinction)
Several columns don't start recording from day one — they show **missing values, not zeros**, until the metric is first triggered:
- `nouveaux_deces` / `deces_cumules`: starts 23/03/2020
- `cas_hebdomadaires`: starts 29/02/2020
- `deces_hebdomadaires`: starts 28/03/2020
- `cas_bihebdomadaires`: starts 07/03/2020
- `deces_bihebdomadaires`: starts 04/04/2020

This makes sense for cumulative-style columns, but there are also isolated missing values *after* a column has started recording (e.g. `nouveaux_cas` for Afghanistan on 20/03/2020 is missing, not 0). **These need to be handled explicitly during ETL — not auto-filled with 0**, since that would misrepresent "no data" as "no cases."

## Data quality — consistency
- Country naming is consistent across all rows checked so far (e.g. "Afghanistan" spelled identically everywhere).
- Numeric columns are properly typed as numbers where populated.
- No formatting inconsistencies found yet in date or country fields.

## `pays` column — non-country rows found
The `pays` column mixes real countries with aggregate/rollup/flawed entries:
- **Continent aggregates:** Africa, Asia, Europe confirmed (others to verify)
- **"International"** — likely cases not attributable to a specific country's health system (e.g. cruise ships, repatriation)
- **"World"** — global total across all countries + continents
- **"Israel** — relabel to Occupied Palestine instead

**Decision:** exclude all non-country rows (continents, International, World) from the fact table during ETL+relabeling Israel to Occupied Palestine. Continent-level views, if needed later, will be derived in Power BI by grouping actual countries — not by trusting the source's pre-aggregated rows.

## Next steps
- Verify remaining continents (Americas, Oceania) for the same aggregate pattern
- Confirm "World" = sum of all real countries (sanity check on a given date)
- Move to star schema design (Dim_Date, Dim_Pays, Fait_Pandemie)