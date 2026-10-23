# ETL log

## dim_temps (loaded)
- 1,143 days, 2020-01-22 → 2023-03-09, calendar complete (no missing days)
- Checks: date and id_temps consistent on all rows (0 mismatches); days expected = days loaded = 1,143
- Issue met: tUniqRow key not set → duplicate-key errors; fixed by ticking `date` as key

## dim_pays (loaded)
- 218 countries and territories, 218/218 with population (2021, OWID/UN WPP 2024)
- Name fixes applied in the tMap lookup key: Faeroe Islands → Faroe Islands, Timor → East Timor
- Issues met: "Action on table" must be Default (drop blocked by the foreign key); insert-only jobs fail on rerun → the master job must truncate first

## fait_pandemie (loaded)
- 233,593 rows, 218 countries, 1,143 days (not every country reports from day 1)
- Validation: SUM(cas_cumules) on 2023-03-09 = 676,466,635 (matches the Excel PivotTable on the source file)
- Issue met: tMap lookup key was placed on `id_pays` instead of `pays` → "cannot convert String to Integer" compile error; fixed by moving the key to `pays`

## Data quality checks (on fait_pandemie, 233,593 rows)
- Negative daily values: 0 (cases), 0 (deaths)
- Cumulative decreases (corrections in the source): 187 (cases), 200 (deaths) = ~0.08%
- NULLs: nouveaux_cas 271 (0.12%), nouveaux_deces 19,825 (8.5%), cas_cumules 2, deces_cumules 19,562 (8.4%), cas_hebdomadaires 1,410 (0.6%), cas_bihebdomadaires 3,072 (1.3%)
- Likely explanations: deaths blank before a country's first reported death; weekly/biweekly windows undefined at the start of each series; daily value blanked when the source corrects a cumulative total
- Decision: data kept as loaded (NULLs stay NULLs); handled in the DAX layer (MAX/last date for cumulative columns)
- All 187 cumulative-case decreases coincide with a NULL nouveaux_cas (the source blanks the daily value when it corrects a total)
- The 2 NULL cas_cumules are early rows (United Kingdom 2020-01-30, Sudan 2020-03-13), not on the final date