# AML Transactions — Data Engineering Project

Production-grade data pipeline built on IBM's synthetic Anti-Money Laundering dataset (HI-Medium, ~32M rows). The project covers incremental ingestion, Kimball dimensional modelling, dbt-native Airflow orchestration, and a Power BI semantic layer - Every architectural decision is deliberate and documented.

---

## Stack

| Layer | Tool |
|---|---|
| Warehouse | Snowflake (Free Tier) |
| Transformation | dbt Core 1.11.11 |
| Adapter | dbt-snowflake 1.11.5 |
| Orchestration | Apache Airflow 3.0+ via Astro CLI + Astronomer Cosmos |
| Dashboard | Power BI |
| CI/CD | GitHub Actions |

---

## Architecture

```
Bronze → Silver → Gold → Marts → Power BI
```

| Layer | Schema | Responsibility |
|---|---|---|
| Bronze | `BRONZE` | Raw landing zone — exact copy of source files via Snowflake internal stage |
| Silver | `SILVER` | Typed, cleaned, conformed — no business logic |
| Gold | `GOLD` | Kimball star schema — `fact_transactions` + 5 dimension tables |
| Marts | `MARTS` | Pre-aggregated business tables — BI |

> 📸 _Architecture diagram_

**Key decisions:**

- `fact_transactions` is incremental by `run_date` — one day processed per Airflow run, simulating a live daily pipeline on a static dataset. The `WHERE transaction_date = '{{ var("run_date") }}'` clause appears unconditionally (no `is_incremental()` guard) so the first-ever table creation only loads one day's slice rather than all 32M rows.
- Amount columns are never summed across currencies. Any mart requiring volume carries `currency` in its grain — enforced consistently across `account_currency_summary`, `hourly_transaction_patterns`, and `bank_flow_matrix`.
- `generate_bank_account_sk` is a shared macro enforcing identical surrogate key generation in both Silver and Gold, preventing the silent FK mismatches that occur when the same MD5 formula drifts between layers.
- Power BI imports exclusively from MARTS — five aggregated tables and six conformed dimension views exposed under the same schema.

---

## Data Model

### Source Files

| File | Description | Load Strategy |
|---|---|---|
| `HI-Medium_Trans.csv` | 32M transaction rows | Incremental, daily by `run_date` |
| `HI-Medium_Accounts.csv` | ~2M account + bank mappings | Full load, one-time |
| `HI-Medium_Patterns_parsed.csv` | 8 AMLSim laundering patterns, pre-processed from raw `.txt` | Full load, one-time |

### Star Schema

`fact_transactions` — 32M rows, incremental. Foreign keys to:

| Dimension | Grain | Notes |
|---|---|---|
| `dim_bank_accounts` | One row per account + bank pair | Surrogate key via shared macro |
| `dim_banks` | One row per bank | Role-playing dimension in `bank_flow_matrix` |
| `dim_date` | One row per minute | Hardcoded calendar spine — independent of fact data |
| `dim_date_no_timestamp` | One row per day | Hardcoded calendar spine — independent of fact data (use any of them depending on your use case) |
| `dim_patterns` | One row per distinct pattern group | Structural descriptors only — no measures |
| `dim_payment_formats` | One row per format | dbt seed — about 7 formats including Reinvestment |

> 📸 _Star schema diagram_

### Marts

| Mart | Grain | Strategy | Powers |
|---|---|---|---|
| `hourly_transaction_patterns` | Date + Hour + Currency + payment_format | Incremental | Overview KPIs, hourly heatmap, currency trend |
| `account_activity_summary` | Account + Date | Incremental | Account drill through |
| `account_currency_summary` | Account + Date + Currency | Incremental | Per-account net flow by currency |
| `bank_flow_matrix` | Bank pair + Currency | Full recreate | - |
| `patterns_summary` | Pattern type | Full recreate | Pattern summary cards |
---

## Orchestration

### DAG Design

Two DAGs with strict separation of concerns:

**`seed_dag`** — manual trigger only, runs once. Loads dbt seeds (`dim_payment_formats`, `dim_currency`).

**`aml_dag`** — `@daily`, `max_active_runs=1`. Eight sequential Cosmos task groups:

```
silver_full_refresh → silver_incremental → gold_dims → gold_fact
    → marts_incremental → marts_views
```

Cosmos reads `manifest.json` at parse time (`LoadMode.DBT_MANIFEST`) and auto-generates one Airflow task per dbt model, respecting all `ref()` dependencies. `run_date` flows from Airflow's `{{ ds }}` macro through Cosmos `operator_args` into dbt's `var("run_date")` — no manual BashOperator wiring.

Dims run before `fact_transactions` (surrogate keys must exist before the fact table joins to them). marts run last — nothing depends on them.

> 📸 _Airflow DAG graph view showing 8 task groups_

### Backfill

28-day static dataset processed sequentially — `max_active_runs=1` enforces one date at a time:

```bash
astro dev run dags backfill \ 
    --start-date YYYY-MM-DD \
    --end-date YYYY-MM-DD \ 
    aml_dag

```

---

## CI/CD

Three GitHub Actions workflows on a two-environment Snowflake setup (`AML` for dev/CI, `AML_PROD` for production):

| Workflow | Trigger | Job |
|---|---|---|
| `ci_dev.yml` | Push to `dev` | `dbt compile` + slim CI tests on changed models + `astro dev parse` |
| `ci_pr.yml` | PR to `main` | Full slim CI gate — must pass before merge is allowed |
| `cd.yml` | Merge to `main` | `dbt compile --target prod` validates against `AML_PROD` + uploads manifest artifact |

**Slim CI** (`ci_pr.yml`) uses `--select state:modified+ --defer --state` against the production manifest artifact uploaded by `cd.yml`. Only models that changed relative to production are rebuilt and tested — unchanged models defer to production data, keeping CI fast and credit-efficient.

Branch protection on `main` requires `dbt-slim-ci` and `airflow-gate` status checks to pass. `cd.yml` runs `dbt compile --target prod` as a code validation gate — Airflow owns all pipeline execution against `AML_PROD`. The compiled manifest is uploaded as an artifact for CI slim comparison.

> 📸 _GitHub Actions CI/CD workflow_


## Visuals




https://github.com/user-attachments/assets/d5a33d94-8b02-43b3-9d16-db7837d0461e




The hourly heatmap is a custom DAX HTML measure using a log-scaled 7-step blue ramp

---

## Dataset

[IBM Transactions for Anti-Money Laundering — Kaggle](https://www.kaggle.com/datasets/ealtman2019/ibm-transactions-for-anti-money-laundering-aml)

---

## License

MIT
