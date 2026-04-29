# Jaffle Shop — MetricFlow Semantic Layer Showcase

This project demonstrates the **dbt Semantic Layer with MetricFlow** end-to-end, using the classic jaffle shop dataset as a foundation. The goal is to show how semantic models and metrics are defined, queried, and composed — not just how dbt models are built.

## Stack

| Tool | Version |
|---|---|
| dbt-core | `>=1.10, <1.11` |
| dbt-duckdb | `>=1.10, <1.11` |
| dbt-metricflow | `>=0.10` |
| Python | `>=3.11` |
| Package manager | [uv](https://docs.astral.sh/uv/) |

---

## Setup

```zsh
./setup.sh
```

The script installs `uv` if missing, creates the venv, installs dbt packages, seeds the data, and runs a full `dbt build`.

`profiles.yml` is kept in the project root. `setup.sh` injects `DBT_PROFILES_DIR` into the venv's activate script, so once you `source .venv/bin/activate` all `dbt` and `mf` commands just work — no conflicts with other projects.

---

## What the semantic layer looks like

Semantic models and metrics are defined in `_semantic_*.yml` files co-located with the mart models they reference. There are three semantic models and 15 metrics across them.

### Semantic models

| Model | Source table | Grain | Entities |
|---|---|---|---|
| `orders` | `fct_orders` | 1 row / order | `order` (primary), `customer` (foreign) |
| `customers` | `dim_customers` | 1 row / customer | `customer` (primary) |
| `payments` | `fct_payments` | 1 row / payment | `payment` (primary), `order`, `customer` (foreign) |

Each semantic model declares:
- **Entities** — the join keys MetricFlow uses to connect models
- **Dimensions** — time (for aggregation windows) and categorical (for `group-by`)
- **Measures** — the raw aggregations (`sum`, `count`, `count_distinct`) that metrics are built from

### Metrics catalogue

**Simple metrics** — a single measure, optionally filtered:

| Metric | Description |
|---|---|
| `total_orders` | Count of all orders |
| `total_revenue` | Gross revenue across all orders |
| `completed_revenue` | Revenue from `status = completed` only |
| `customers_with_orders` | Distinct customers who placed an order |
| `total_customers` | All customers in the system |
| `active_customers` | Customers with at least one order |
| `total_payments` | Count of payment transactions |
| `total_payment_volume` | Total dollar volume of payments |

**Ratio metrics** — numerator / denominator, each can carry a filter:

| Metric | Formula |
|---|---|
| `average_order_value` | `revenue / orders` |
| `order_completion_rate` | `completed orders / total orders` |
| `average_lifetime_value` | `total LTV / customers` |
| `average_orders_per_customer` | `total orders / customers` |
| `credit_card_share` | `credit card payments / total payments` |

**Cumulative metrics** — running totals over a time window:

| Metric | Window |
|---|---|
| `revenue_last_28d` | Rolling 28 days |
| `cumulative_revenue` | All time |

**Derived metrics** — composed from other metrics with an expression:

| Metric | Formula |
|---|---|
| `revenue_growth_mom` | `(revenue - revenue_prev_month) / revenue_prev_month` |

---

## Exploring the semantic layer

MetricFlow ships with a set of `list` and `explain` sub-commands that let you inspect every object in the semantic layer without writing SQL or opening a BI tool.

### List commands

```bash
# All 17 metrics across the three semantic models
mf list metrics

# Filter metrics by name — matches total_revenue, completed_revenue, cumulative_revenue, etc.
mf list metrics --search revenue

# All queryable dimensions across every semantic model
mf list dimensions

# Dimensions available for total_revenue (orders model + joined customer dims)
mf list dimensions --metrics total_revenue
# → metric_time, order__order_date, order__status, order__is_completed,
#   order__is_returned, customer__customer_segment, customer__full_name, …

# Dimensions shared across total_revenue + total_payment_volume
# (only dims reachable from both metrics are returned)
mf list dimensions --metrics total_revenue,total_payment_volume

# All entities MetricFlow knows about
mf list entities
# → order, customer, payment

# Entities available when querying active_customers
mf list entities --metrics active_customers
# → customer

# All three semantic models
mf list semantic-models
# → orders, customers, payments
```

### Explain: see the generated SQL before running it

```bash
# Cross-model query: revenue + AOV broken down by customer segment
# MetricFlow joins orders → customers via the customer entity
mf explain \
  --metrics total_revenue,average_order_value \
  --group-by customer__customer_segment,metric_time__month

# Cumulative metric — inspect the window frame SQL
mf explain \
  --metrics revenue_last_28d \
  --group-by metric_time__day

# Ratio metric — see how numerator/denominator subqueries are assembled
mf explain \
  --metrics average_lifetime_value \
  --group-by customer__customer_segment

# Payment method breakdown — payments model dimensions
mf explain \
  --metrics total_payment_volume,total_payments \
  --group-by payment__payment_method,metric_time__month
```

`mf explain` is the fastest way to audit what SQL the semantic layer produces — useful when onboarding a new metric or debugging unexpected results.

---

## Querying metrics with MetricFlow

The `mf` CLI (installed with `dbt-metricflow`) lets you query any metric without writing SQL.

```bash
# Revenue by week
mf query \
  --metrics total_revenue \
  --group-by metric_time__week

# Multiple metrics + breakdown by payment method
mf query \
  --metrics total_revenue,total_orders,average_order_value \
  --group-by metric_time__month

# Completion rate trend
mf query \
  --metrics order_completion_rate \
  --group-by metric_time__month

# Rolling 28-day revenue
mf query \
  --metrics revenue_last_28d \
  --group-by metric_time__day

# Customer metrics by segment
mf query \
  --metrics active_customers,average_lifetime_value \
  --group-by customer__customer_segment

# Cross-model: revenue per customer segment (entities join orders → customers)
mf query \
  --metrics total_revenue,average_order_value \
  --group-by customer__customer_segment,metric_time__month

# Payment method mix
mf query \
  --metrics total_payment_volume,credit_card_share \
  --group-by payment__payment_method,metric_time__month

# Validate all semantic models
mf validate-configs
```

---

## How MetricFlow resolves queries

When you run `mf query --metrics total_revenue --group-by customer__customer_segment`, MetricFlow:

1. Looks up `total_revenue` → measure `revenue` on semantic model `orders`
2. Resolves `customer__customer_segment` → dimension `customer_segment` on semantic model `customers`
3. Finds the join path: `orders.customer` (foreign) → `customers.customer` (primary)
4. Generates and executes the SQL join automatically

This means **you define the join graph once** in semantic models and every BI tool or `mf query` call gets consistent, pre-validated SQL — no per-dashboard join logic.

---

## Project structure

```
models/
├── staging/          stg_* views — rename & cast raw sources
├── intermediate/     int_* ephemeral — assemble business logic
└── marts/
    ├── core/
    │   ├── dim_customers.sql
    │   ├── fct_orders.sql
    │   ├── _core_models.yml       schema tests + docs
    │   ├── _semantic_orders.yml   semantic model + metrics for orders
    │   └── _semantic_customers.yml
    └── finance/
        ├── fct_payments.sql
        ├── fct_mrr.sql
        ├── _finance_models.yml
        └── _semantic_payments.yml
```

---

## Running tests

```bash
dbt test                    # all tests
dbt test --select staging   # staging only
dbt test --select marts     # marts only
mf validate-configs         # validate semantic models & metrics
```

## Docs

```bash
dbt docs generate && dbt docs serve
```
