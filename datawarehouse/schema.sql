-- Star schema: COVID-19 monitoring (grain: one country x one day)

CREATE TABLE dim_temps (
  id_temps    INTEGER PRIMARY KEY,      -- format YYYYMMDD, e.g. 20200224
  date        DATE NOT NULL UNIQUE,
  annee       SMALLINT NOT NULL,
  trimestre   SMALLINT NOT NULL,
  mois        SMALLINT NOT NULL,
  semaine_iso SMALLINT NOT NULL
);

CREATE TABLE dim_pays (
  id_pays     SERIAL PRIMARY KEY,
  pays        VARCHAR(100) NOT NULL UNIQUE,
  population  BIGINT                    -- OWID / UN WPP 2024, year 2021
);

CREATE TABLE fait_pandemie (
  id_temps               INTEGER NOT NULL REFERENCES dim_temps(id_temps),
  id_pays                INTEGER NOT NULL REFERENCES dim_pays(id_pays),
  nouveaux_cas           INTEGER,
  nouveaux_deces         INTEGER,
  cas_cumules            BIGINT,
  deces_cumules          BIGINT,
  cas_hebdomadaires      BIGINT,
  deces_hebdomadaires    BIGINT,
  cas_bihebdomadaires    BIGINT,
  deces_bihebdomadaires  BIGINT,
  PRIMARY KEY (id_temps, id_pays)       -- enforces the grain
);