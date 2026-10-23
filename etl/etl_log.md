# ETL log

## dim_temps (loaded)
- 1,143 days, 2020-01-22 → 2023-03-09, calendar complete (no missing days)
- Checks: date and id_temps consistent on all rows (0 mismatches); days expected = days loaded = 1,143
- Issue met: tUniqRow key not set → duplicate-key errors; fixed by ticking `date` as key

## dim_pays (loaded)
- 218 countries and territories, 218/218 with population (2021, OWID/UN WPP 2024)
- Name fixes applied in the tMap lookup key: Faeroe Islands → Faroe Islands, Timor → East Timor
- Issues met: "Action on table" must be Default (drop blocked by the foreign key); insert-only jobs fail on rerun → the master job must truncate first