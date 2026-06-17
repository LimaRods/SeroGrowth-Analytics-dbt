# FiOps — back-office read models (dbt)

The CQRS **read side** over the contract engine's append-only landing layer
(`OPERATION_DB`). dbt only **reads** the operational data and projects it into
**`ANALYTICAL_LAYER`** marts for reporting, risk, compliance and ops. The engine
is the only writer of the source data.

```
contract-engine ──► OPERATION_DB(.CORE/.CONTRACT/.REGISTRY/.OPS)  ──dbt──►  ANALYTICAL_LAYER (marts)
   (write side)            sources (this folder reads)                        (read side, this folder builds)
```

---

## Reads — which operational DB each environment uses

Every source's database is resolved by [`_fiops__sources.yml`](./_fiops__sources.yml):

```jinja
{{ env_var('OPERATION_DB_NAME', 'OPERATION_DEV_DB' if target.name == 'dev' else 'OPERATION_DB') }}
```

An explicit `OPERATION_DB_NAME` env var **wins**; otherwise it falls back to the
target name. (Same env var `run_ddl.py` and the loader use.)

| Target / env | `OPERATION_DB_NAME` | Reads from |
| --- | --- | --- |
| dev | `OPERATION_DEV_DB` | `OPERATION_DEV_DB` |
| preprod | *(unset)* | `OPERATION_DB` |
| prod | *(unset)* | `OPERATION_DB` |

## Writes — where models land

Output **database** is forced to `ANALYTICAL_LAYER` by `dbt_project.yml`
(`FiOps: +database: ANALYTICAL_LAYER`). Output **schema** = the target's schema
(no `generate_schema_name` override). Net:

| Target / env | Output schema | Models land in |
| --- | --- | --- |
| dev | `DBT_DOLFO` | `ANALYTICAL_LAYER.DBT_DOLFO` |
| preprod | `PREPROD` | `ANALYTICAL_LAYER.PREPROD` |
| prod | `SERO_X` | `ANALYTICAL_LAYER.SERO_X` |

---

## ⚠️ dbt Cloud setup (profiles.yml is IGNORED on Cloud)

On dbt Cloud the routing comes from each **Environment**, not `profiles.yml`
(Cloud reports `target.name` as `default`). Set per environment:

| Environment | Env var to set | Schema (in credentials) | Net: reads → writes |
| --- | --- | --- | --- |
| **dev** | `OPERATION_DB_NAME=OPERATION_DEV_DB` | `DBT_DOLFO` | OPERATION_DEV_DB → ANALYTICAL_LAYER.DBT_DOLFO |
| **preprod** | *(none)* | `PREPROD` | OPERATION_DB → ANALYTICAL_LAYER.PREPROD |
| **prod** | *(none)* | `SERO_X` | OPERATION_DB → ANALYTICAL_LAYER.SERO_X |

You do **not** set the output database in Cloud — `+database` forces it.
**Critical:** without `OPERATION_DB_NAME=OPERATION_DEV_DB` on the dev environment,
dev runs read prod `OPERATION_DB` (empty) instead of the dev sandbox.

## Local runs (uses `profiles.yml` in this dir)

```bash
dbt build --select FiOps --target dev        # → reads OPERATION_DEV_DB, writes DBT_DOLFO
dbt build --select FiOps --target preprod     # → reads OPERATION_DB,     writes PREPROD
# select a layer/venue:
dbt build --select FiOps.marts.risk
```

`profiles.yml` already maps dev→`DBT_DOLFO`, preprod→`PREPROD`, prod→`SERO_X`
(all in `ANALYTICAL_LAYER`); default target is `dev` (a safety so a bare
`dbt run` can't touch prod).

---

## Model layers

- **sources** (`_fiops__sources.yml`) — all tables across the 4 schemas:
  `core`, `contract`, `registry`, `ops`.
- **staging/** — thin `select *` pass-throughs (one per source table used).
- **marts/**
  - `dim_deal_current`, `deal_events_current`, `dim_contract` — shared dims/views.
  - `reporting/` — `rpt_client_book`, `rpt_fund_cota_history`, `rpt_trade_settlements`.
  - `risk/` — `risk_margin_calls`, `risk_trs_mtm_latest`, `risk_exposure_by_dimension`.
  - `compliance/` — `audit_corrections`, `audit_human_review`, `audit_execution_chain`.
  - `ops/` — `ops_execution_throughput`, `ops_review_queue`.

## Population status (2026-06)

| Source | Populated? | Notes |
| --- | --- | --- |
| `CONTRACT.contracts`, `contract_templates` | ✅ | |
| `CORE.executions`, `deal_events`, `deal_snapshots` | ✅ | |
| `CORE.deal_references`, `CONTRACT.template_field_registry`, `contract_sources` | ❌ | declared, empty |
| `REGISTRY.*` | ❌ | seed pending — `stg_clients`/`stg_sources` empty until then |
| `OPS.*` | ❌ | seed pending — `ops_review_queue` is a structural prototype |

Models on unpopulated sources build successfully but return **zero rows** until
those tables are seeded. Volume in `OPERATION_DEV_DB` is produced by
`contract-engine/simulate.py` + loaded with `data_layer/ingestion/load_to_snowflake.py
--database OPERATION_DEV_DB`. Only `OPERATION_DEV_DB` is loaded today; preprod/prod
(`OPERATION_DB`) are empty until loaded.
