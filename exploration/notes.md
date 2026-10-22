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
The `pays` column mixes real countries with aggregate rows. Full list of aggregates found via a PivotTable on `pays`:

- **Continents (6):** Africa, Asia, Europe, North America, South America, Oceania (Antarctica is absent from the data)
- **European Union:** regional aggregate, a subset of Europe
- **Income groups ([4]):** [High income, Upper middle income,Lower middle income,Low income ...]
- **International:** cases not attributable to any country (e.g. cruise ships)
- **World:** global total

**Decision:** exclude all aggregate rows from the fact table during ETL. Continent-level views, if needed, will be derived in Power BI by grouping real countries, not by trusting the source's pre-aggregated rows.

**Real countries:** [total distinct `pays` values] − [number of aggregates] = **[number] countries**

## Sanity check: how is "World" built?
Compared on 09/03/2023 using a PivotTable (sum of `cas_cumules`):

- Sum of real countries: 676,466,635
- World: 676,467,356
- Gap: 721 = exactly the value of **International** on that date

**Conclusion:** World = sum of real countries + International. Continents, the EU and income groups are alternative groupings of the same total, so adding them together would count the same people several times. Excluding the aggregates from the fact table loses no information.

## Population enrichment
- Source: Our World in Data, population-unwpp (UN WPP 2024), historical estimates
- Reference year: 2021, treated as constant over 2020–2023 (simplification stated in the report)
- Name mismatches (2 of 218): Faeroe Islands → Faroe Islands, Timor → East Timor
- Coverage after mapping: 218/218 countries have a population