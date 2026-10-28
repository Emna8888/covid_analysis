# COVID-19 Pandemic Monitoring: an end-to-end BI pipeline

A complete Business Intelligence chain built on real COVID-19 data for **218 countries and territories**: dimensional model, PostgreSQL data warehouse, automated Talend ETL, Power BI dashboard, machine learning in Python, and an IBM Cognos report.


## At a glance

| | |
|---|---|
| Source data | Daily cases and deaths per country, 2020-01-22 to 2023-03-09 |
| Warehouse | PostgreSQL 16, star schema (1 fact table, 2 dimensions) |
| Rows loaded | **233,593** fact rows, 1,143 days, 218 countries and territories |
| ETL | Talend Open Studio 8.0.1: 4 jobs, rebuilt end to end by one master job |
| Dashboard | Power BI, 3 pages, DAX measures |
| ML | k-means clustering of countries, Prophet forecast evaluated against a naive baseline |
| Reporting | IBM Cognos Analytics report (PDF in `rapport/`) |
| Validation | Total cumulative cases on 2023-03-09 = **676,466,635**, identical in Excel, SQL, Power BI and Python |

## Architecture

```
corona_timeseries_monde.csv + population (OWID / UN WPP 2024)
        |
        v   Talend: filter aggregates, deduplicate, look up keys, load
PostgreSQL star schema (covid_dw)
        |
        |--> Power BI (relationships, DAX measures, 3 report pages)
        |
        '--> Python: pandas, scikit-learn (k-means), Prophet  -->  CSV  -->  IBM Cognos report
```

## Data model (star schema)

| Table | Grain / content |
|---|---|
| `fait_pandemie` | One row per country per day: daily, cumulative, 7-day and 14-day cases and deaths |
| `dim_temps` | One row per day (1,143 days): year, quarter, month, ISO week |
| `dim_pays` | One row per country (218): name and 2021 population |

Design choices: technical integer keys, 13 aggregate rows excluded (6 continents, European Union, 4 income groups, International, World) to avoid double counting, NULLs kept as NULLs, ratios computed in DAX rather than stored. The SQL is in `datawarehouse/schema.sql`.

## ETL (Talend)

| Job | Role |
|---|---|
| `job_dim_temps` | Builds the calendar (1,143 distinct dates) |
| `job_dim_pays` | Builds the country dimension and joins the 2021 population (2 name fixes: Faeroe Islands, Timor) |
| `job_fait_pandemie` | Loads the fact table with a key lookup on `dim_pays` |
| `job_master_etl` | Truncates the tables, then runs the three jobs in order |

Every job was validated by row counts in the database and against an independent figure from the source. Details, problems met and data-quality results are in [`etl/etl_log.md`](etl/etl_log.md).

## Power BI

Three pages in `powerbi/covid_dashboard.pbix`:

1. **Overview**: KPI cards, daily cases with a 7-day average, year and country slicers
2. **Country comparison**: top 10 by cases per 100,000 (population of 1 million or more), Tunisia and its neighbours, comparison table
3. **Critical periods**: year-by-month heatmap and peak-week cards

DAX measures include cumulative values at the last selected date, case fatality rate, cases and deaths per 100,000, a 7-day moving average and the peak week.

## Machine learning (`ML/`)

| Notebook | Content |
|---|---|
| `01_load_data.ipynb` | Reads the warehouse into pandas and checks the 676,466,635 total |
| `02_clustering.ipynb` | k-means on five features per country; outlier handling; choice of k by a rule written in advance |
| `03_forecast.ipynb` | Weekly series for Tunisia; Prophet vs naive baseline with a rolling backtest |

**Clustering:** 157 countries, k = 3 (silhouette 0.391, weak structure):

| Cluster | Countries | Median cases / 100k | Median deaths / 100k | Fatality rate |
|---|---|---|---|---|
| Low reported burden | 90 | 1,372 | 18 | 1.3% |
| High incidence, low case fatality | 40 | 43,748 | 200 | 0.5% |
| Moderate incidence, high mortality | 27 | 12,894 | 293 | 2.3% |

**Forecast:** Prophet did **not** beat a naive baseline (mean absolute error 13,260 against 10,606 cases per week over four test periods), so the forecast is presented as illustrative.

## Findings (Tunisia as an example)

- 1,151,126 cumulative cases (9,554 per 100,000), case fatality rate 2.55%
- Worst week: 66,015 cases, ending 22-23 January 2022
- Belongs to the "moderate incidence, high mortality" group

## Limitations

- Counts depend on testing and reporting, which differ between countries; a low case fatality rate does not mean a milder disease.
- The cluster groups overlap (silhouette below 0.5): they segment a continuum rather than reveal natural categories. North Korea and Yemen were excluded as implausible (fatality above 10% of recorded cases).
- The data contains corrections: 187 decreases in cumulative cases and 200 in deaths (about 0.1% of rows); the source blanks the daily value on those days.
- Population is a single reference year (2021) applied to the whole period.
- The last weekly point of the Tunisia series covers only part of a week.

## Repository structure

```
datawarehouse/   schema.sql (star schema)
etl/             etl_log.md (jobs, checks, problems)
exploration/     notes.md (findings about the source data)
ML/              three Jupyter notebooks
powerbi/         covid_dashboard.pbix
rapport/         cognos_report.pdf
```

Data files are not in the repository (they are git-ignored). The Talend project export is also left out because it embeds database connection details; `etl/etl_log.md` documents the job design.

## Reproduce it

1. Install PostgreSQL 16, create a database `covid_dw`, and run `datawarehouse/schema.sql`.
2. Put the two source CSV files in `data/` and rebuild the four Talend jobs as described in `etl/etl_log.md` (Talend Open Studio 8.0.1, Java 11).
3. Run `job_master_etl`, then check: `SELECT SUM(cas_cumules)` on 2023-03-09 must equal 676,466,635.
4. Python (3.12):
   ```
   py -3.12 -m venv .venv
   .venv\Scripts\activate
   pip install pandas numpy sqlalchemy psycopg2-binary scikit-learn matplotlib prophet ipykernel
   ```
   then run the notebooks in `ML/` in order. The database password is requested at run time and is never stored.

## Data sources

- Daily COVID-19 time series (country level), provided for the course project.
- Population: Our World in Data, based on the UN World Population Prospects 2024 (reference year 2021).

