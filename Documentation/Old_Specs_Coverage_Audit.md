# Old Specs Coverage Audit

Date: 2026-03-30

This audit tracks specs moved to `old_specs/`, why they fail today, and whether equivalent
coverage exists in active specs under `specs/` (`*_spec.rb` and remaining passing `*.spec.rb`).

## Moved Specs

- `old_specs/r_arrow_integration.spec.rb`
- `old_specs/r_dataframe.spec.rb`
- `old_specs/r_environment.spec.rb`
- `old_specs/r_formula.spec.rb`
- `old_specs/r_language.spec.rb`
- `old_specs/r_list.spec.rb`
- `old_specs/r_plots.spec.rb`
- `old_specs/ruby_expression.spec.rb`

## Failure Classification (current environment)

- **Dependency/tooling missing in R session**
  - `r_arrow_integration.spec.rb`: `write_feather` missing
  - `r_environment.spec.rb`: `env()` missing
  - `r_plots.spec.rb`: `evaluate_plot_snapshot()` missing
  - `ruby_expression.spec.rb`: `call2` / `exec` missing
- **Expectation mismatch due to bridge semantics**
  - `r_dataframe.spec.rb`: expects `RuntimeError`, now raises `NewBridge::SessionClient::RProcessError`
  - `r_list.spec.rb`: expects `ArgumentError`, now raises `NewBridge::SessionClient::RProcessError`
  - `ruby_expression.spec.rb`: expects `R.expr(:len)` to produce `R::RSymbol`, currently returns `Symbol`; dispatch probe mismatch

## Coverage Mapping vs Active Specs

### 1) `old_specs/r_arrow_integration.spec.rb`

- **Old scope:** Arrow table conversion, Feather roundtrip, Arrow dataset + dplyr pipeline.
- **Equivalent active coverage found:** **Yes (converted).**
- **Nearest active specs:**
  - `specs/arrow_semantics_spec.rb` (table conversion, Feather roundtrip, Parquet dataset + dplyr aggregation).
- **Gap status:** **COVERED**.

### 2) `old_specs/r_dataframe.spec.rb`

- **Old scope:** DataFrame creation, indexing/subsetting, assignment, iteration, bootstrap behavior.
- **Equivalent active coverage found:** **Partial (improved).**
- **Nearest active specs:**
  - `specs/dataframe_semantics_spec.rb` (creation, key `[ ]`/`[[ ]]` paths, assignment, bridge-error expectation)
  - `specs/protocol_result_spec.rb` (returns `R::DataFrame` handle)
  - `specs/field_access_spec.rb` (column access semantics via `[[`).
- **Gap status:** **PARTIAL GAP** (iteration/bootstrap sub-areas still missing).

### 3) `old_specs/r_environment.spec.rb`

- **Old scope:** Environment creation, set/get, eval in mask, subset restrictions.
- **Equivalent active coverage found:** **Partial (improved).**
- **Nearest active specs:**
  - `specs/environment_semantics_spec.rb` (creation via `new.env`, set/get, dot assignment, remove, invalid `[]` semantics)
- **Gap status:** **PARTIAL GAP** (legacy expression-mask eval path still missing).

### 4) `old_specs/r_formula.spec.rb`

- **Old scope:** Formula operators and model fitting.
- **Equivalent active coverage found:** **Partial (improved).**
- **Nearest active specs:**
  - `specs/formula_semantics_spec.rb` (formula DSL construction, interaction operators, model.frame, `lm` + `predict`)
- **Gap status:** **PARTIAL GAP** (legacy dependency-heavy scenarios using `ISLR`/`MASS` are intentionally not in fast suite).

### 5) `old_specs/r_language.spec.rb`

- **Old scope:** Symbol/language/formula execution semantics in list contexts.
- **Equivalent active coverage found:** **Partial (improved).**
- **Nearest active specs:**
  - `specs/language_expression_semantics_spec.rb` (symbol conversion, expression build/eval, eval in context, subset with expression)
- **Gap status:** **PARTIAL GAP** (formula-specific legacy scenarios are deferred to formula migration).

### 6) `old_specs/r_list.spec.rb`

- **Old scope:** List creation, subsetting (`>>`, `[`, `[[`, `.`), assignment, iteration.
- **Equivalent active coverage found:** **Partial (improved).**
- **Nearest active specs:**
  - `specs/list_semantics_spec.rb` (creation, core subsetting, dot/named assignment, bridge-error expectation)
  - `specs/protocol_result_spec.rb` (list handle type + protocol behavior)
  - `specs/unboxing_spec.rb` (list unboxing semantics)
  - `specs/field_access_spec.rb` (named list field access).
- **Gap status:** **PARTIAL GAP** (iteration and some advanced indexing/assignment paths still missing).

### 7) `old_specs/r_plots.spec.rb`

- **Old scope:** Plot device snapshot/save path.
- **Equivalent active coverage found:** **None in active fast specs.**
- **Related coverage elsewhere:** `slow-specs/phase2_gknit_chunk_output_spec.rb` validates rendered outputs, but not direct `R::Device#plot_snapshot` contract.
- **Gap status:** **GAP**.

### 8) `old_specs/ruby_expression.spec.rb`

- **Old scope:** Symbol-to-expression semantics, call construction, tidy eval helpers.
- **Equivalent active coverage found:** **Partial (improved).**
- **Nearest active specs:**
  - `specs/language_expression_semantics_spec.rb` (core symbol expression semantics under NewBridge)
- **Gap status:** **PARTIAL GAP** (`R.expr`, `call2`, `exec`, and dispatch-probe-dependent helpers remain unresolved/missing in current runtime).

## Recommendation

1. Keep `old_specs/` isolated and runnable via `bin/run_old_rspec`.
2. Reintroduce coverage by adding new focused `*_spec.rb` tests in `specs/` per feature area, aligned with current NewBridge semantics:
   - normalize expected exception classes to `NewBridge::SessionClient::RProcessError` where appropriate;
   - explicitly install/load optional R dependencies when required (arrow/rlang/tidyverse helpers), or mark as integration + skip with clear message.
3. Prioritize new specs in this order:
   - DataFrame/list indexing semantics
   - Ruby expression/language semantics
   - Environment API
   - Arrow integration
   - Plot snapshot contract
