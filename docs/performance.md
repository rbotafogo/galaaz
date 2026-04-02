# Galaaz Performance Improvement Plan

This document defines a focused plan to reduce Ruby<->R bridge overhead for real workloads such as DESeq2.

## Goal

Reduce end-to-end latency in `galaaz` by minimizing avoidable bridge round-trips and wrapper/introspection overhead, while preserving existing API behavior.

## Observed Baseline (DESeq2 Airway)

From local benchmark discussions:

- `Rscript` full run: ~26s median
- `galaaz` full run (new process): ~79s median
- `galaaz` warm loop (same process): ~45s median

Key observation:

- Core DESeq compute time is similar between pure R and `galaaz`.
- Main overhead is in setup/interoperability phases, not statistical model computation itself.

For a **fair warm comparison** (R and galaaz each running the pipeline **three times in one process**, PDF plot aligned), see [deseq2_airway_benchmark.md](./deseq2_airway_benchmark.md). On a representative run, **R warm (~14 s)** and **galaaz optimized warm (~14 s)** can match; rerun the harness to account for variance.

## Scope

In scope:

- Result protocol metadata improvements (`eval_r_with_result` envelope)
- Wrapper construction and class probing optimization
- Method dispatch/probe optimization and caching
- Benchmark instrumentation to verify improvements

Out of scope:

- Any optimization of deprecated `shadow_bridge` internals
- Changes to user-facing API semantics unless explicitly required

## Improvement Tracks

### 1) Make result envelopes fully wrapper-ready (high priority)

Current path can still fall back to extra introspection when wrapper type is ambiguous.

- Files: `lib/R_interface/new_bridge_adapter.rb`, `lib/new_bridge/session_client.rb`, `lib/R_interface/robject.rb`
- Plan:
  - Ensure every handle return from `eval_r_with_result` includes stable wrapper metadata.
  - Add a normalized wrapper tag in envelope (example: `vector`, `data_frame`, `matrix`, `list`, `closure`, `environment`, `language`, `symbol`, `other`).
  - Keep `r_class` string for debugging/compatibility, but avoid additional `class(...)` calls in Ruby when tag is present.
- Expected impact:
  - Remove one extra introspection round-trip in common paths.
  - Reduce per-call latency in setup-heavy pipelines.

### 2) Avoid fallback `class(...)` in `Object.build` except true unknowns

`Object.build` should prefer envelope metadata and only probe class when metadata is missing.

- File: `lib/R_interface/robject.rb`
- Plan:
  - Add explicit constructor path: `Object.build(handle, expression, r_class:, wrapper_tag:)`.
  - Make `class(...)` probing opt-in fallback only for unknown/legacy envelopes.
  - Add debug counters for fallback probe frequency.
- Expected impact:
  - Fewer hidden round-trips.
  - Better observability of protocol completeness.

### 3) Reduce dispatch probing on known function calls

`method_missing/process_missing` may trigger extra checks (`is_field`, `is_func`) that are unnecessary for obvious function-style calls.

- File: `lib/R_interface/rsupport.rb`
- Plan:
  - Fast-path module calls like `R.foo(...)` directly to function execution where safe.
  - Keep field/function probing for receiver-object ambiguity cases (`obj.name`).
  - Strengthen and expand probe cache for repeated symbols.
- Expected impact:
  - Lower control-plane overhead on hot call paths.

### 4) Collapse setup chains into fewer bridge evals where safe

Some high-level Ruby lines currently produce multiple round-trips.

- Files: `lib/R_interface/rsupport.rb`, selected examples/bench scripts
- Plan:
  - Identify common chains (`counts -> rowSums -> compare`, subsetting with `:all`) and evaluate whether they can be sent as one composed R expression through existing APIs.
  - Preserve readability and semantics; only optimize where behavior is identical.
- Expected impact:
  - Fewer command round-trips in setup.

### 5) Add performance instrumentation and regression guardrails

Need repeatable signals to prevent regressions and validate gains.

- Files: `specs/` (new performance-focused specs), `docs/` benchmark notes
- Plan:
  - Add optional debug counters: round-trip count, fallback class probes, dispatch probe hits/misses.
  - Add micro-benchmark script/spec for setup phase and warm-loop throughput.
  - Track baseline and post-change medians for:
    - startup
    - setup
    - compute
    - output/plot
- Expected impact:
  - Measurable validation of each optimization step.

### 6) Add batching API (explicit first, transparent later)

Per-call bridge overhead is significant even when payloads are small. Batching reduces control-plane cost by sending multiple operations in one bridge packet.

- Files: `lib/R_interface/rsupport.rb`, `lib/R_interface/new_bridge_adapter.rb`, `lib/new_bridge/session_client.rb`, gatekeeper `__G_BATCH_EVAL_WITH_RESULT__` in `ext/new_bridge/galaaz_gatekeeper_phase1.cpp`
- Plan:
  - Introduce explicit API first: `R.batch do ... end`. **Shipped** — see [R.batch (explicit eval batching)](#rbatch-explicit-eval-batching) below.
  - Within a batch, queue compatible R operations and execute in order as one multi-op request.
  - Return per-op envelopes so Ruby can preserve object handles/types exactly.
  - Add optional auto-batch micro-window later for transparent coalescing (not done).
- Expected impact:
  - Significant round-trip reduction in setup and output-heavy scripts.
  - Lower latency without changing user-level code structure.

### 7) Make batching compatible with common `puts` usage

`puts` itself is Ruby-local, but interpolated `R.*` calls can be coalesced before printing.

- Files: `lib/R_interface/rsupport.rb` (call capture), adapter/session protocol files
- Plan:
  - Support batching for expression resolution that happens before `puts`.
  - Preserve operation order and deterministic side effects.
  - Keep error mapping per sub-operation for debuggability.
- Expected impact:
  - Output/reporting blocks benefit from batching without forcing users to stop using `puts`.
  - Reduced bridge chatter in diagnostics-heavy scripts.

### 8) Prepared expression/function cache on R side

Repeated parse/eval/dispatch for the same call shape adds avoidable overhead.

- Files: adapter/session protocol + R-side helper code for prepared handles
- Plan:
  - Add `prepare`/`call_prepared` protocol:
    - prepare once (parse + bind function shape)
    - call many times with args only
  - Use for repeated patterns (summary prints, common transforms, simple aggregations).
- Expected impact:
  - Lower CPU and latency on repeated call patterns.

### 9) Persistent session warmup and object/symbol pools

Cold startup and repeated setup are expensive.

- Files: session bootstrap and runtime management paths
- Plan:
  - Keep long-lived bridge sessions in normal workflows.
  - Preload commonly used libraries/symbols/formula helpers.
  - Reuse stable handles when safe.
- Expected impact:
  - Better steady-state performance for iterative and notebook-like usage.

### 10) Binary protocol improvements and reduced object churn

Control overhead includes packet serialization and frequent wrapper allocations.

- Files: adapter/session envelope protocol, object construction paths
- Plan:
  - Keep envelopes compact and binary-friendly for scalar/meta responses.
  - Reuse wrappers for stable handles when safe.
  - Minimize temporary Ruby object creation in hot paths.
  - Evaluate JVM/JRuby tuning and Java-level hot path optimization before any low-level unsafe approach.
- Expected impact:
  - Lower overhead per operation and lower GC pressure.

## Batching API Feasibility Notes

Batching is feasible without requiring users to rewrite scripts into embedded R code.

- `puts` is not the bottleneck by itself; the expensive part is resolving `R.*` values used by `puts`.
- Batching can coalesce those `R.*` evaluations before `puts` executes.
- Recommended rollout:
  1. explicit `R.batch` API (lowest risk) — **available**; semantics are documented in [R.batch (explicit eval batching)](#rbatch-explicit-eval-batching).
  2. benchmark and validate correctness,
  3. optional transparent auto-batching for common call patterns.

## R.batch (explicit eval batching)

The **`R.batch`** API runs several **`eval_r_with_result`-style assignments** in **one** bridge REQ/RET, reducing round-trips for setup-heavy Ruby code. It is the user-facing half of improvement track 6; implementation details and checklist live in [performance_plan.md](./performance_plan.md) (Phase 4).

### Usage

```ruby
require 'galaaz'

v1 = R::Support.generate_var_name
v2 = R::Support.generate_var_name

envelopes = R.batch do |b|
  b.eval_with_result("#{v1} <- 1L")
  b.eval_with_result("#{v2} <- #{v1} + 2L")
end

# Same legacy envelope hashes as sequential R.bridge.eval_r_with_result / Support paths:
# envelopes[0][:type] => :scalar_integer, envelopes[0][:value] => 1, etc.
vec = R::Object.build(envelopes[1][:handle], nil,
                      r_class: envelopes[1][:r_class],
                      wrapper_tag: envelopes[1][:wrapper_tag])
```

Each string passed to **`b.eval_with_result`** must be a **single assignment** in the same form the bridge already accepts after `__G_EVAL_WITH_RESULT__` (for example `"g2_v12 <- c(1, 2, 3)"`). Generate names with **`R::Support.generate_var_name`** so handles stay valid.

### Semantics

- **Ordering:** ops run in the order they were queued; results are returned as an **array of envelopes** in that same order.
- **Fail-fast:** if op *k* fails in R, **later ops are not executed**. Ruby raises **`R::BatchEvaluationError`** with **`#failed_index`** (0-based) and the R error message. Earlier ops remain committed in the session environment, matching sequential `eval_r_with_result` behavior up to the failure.
- **Empty batch:** `R.batch` with no `eval_with_result` calls raises **`ArgumentError`**.
- **Limits:** at most **256** ops per batch; segments are separated on the wire by ASCII RS (`0x1E`). Assignments must not embed that byte.

### What is not batched here

This path only batches **eval-with-result assignments**. It does not combine arbitrary bridge commands (for example `__G_DISPATCH_PROBE__`, `__G_PULL_VECTOR__`, or plain side-effect `eval_r` snippets). Those still use the existing one-op APIs.

### References

- Ruby: `R.batch`, `R::BatchEvaluationError` in `lib/R_interface/r.rb`; collector and `R::Support.batch_eval_with_result` in `lib/R_interface/rsupport.rb`; `R::NewBridgeAdapter#batch_eval_r_with_result` in `lib/R_interface/new_bridge_adapter.rb`.
- Gatekeeper: `__G_BATCH_EVAL_WITH_RESULT__` in `ext/new_bridge/galaaz_gatekeeper_phase1.cpp`.
- Tests: `specs/r_batch_fail_fast_spec.rb`.

## Proposed Execution Sequence

1. Implement envelope wrapper tags and Ruby-side use of tags.
2. Remove class-probe fallback from hot path (keep fallback for unknown legacy cases).
3. Add dispatch fast-path and cache improvements.
4. Implement explicit batching API (`R.batch`) with per-op envelopes.
5. Re-benchmark DESeq2 setup/output and warm-loop with batching enabled.
6. Add prepared-expression cache for repeated call shapes.
7. Apply expression-collapsing only if additional gains are still needed.

## Acceptance Criteria

- Functional:
  - Existing tests pass with no user-facing behavior regressions.
  - Bioconductor DESeq2 example still runs successfully.
- Performance (initial target):
  - Reduce setup-phase overhead by at least 25% in DESeq2 benchmark.
  - Reduce warm-loop median for `galaaz` on DESeq2 by at least 20%.
- Observability:
  - New counters clearly show fewer fallback class probes and fewer dispatch probes.

## Risks and Mitigations

- Risk: wrapper misclassification from envelope tags.
  - Mitigation: keep strict fallback path + targeted tests per wrapper type.
- Risk: dispatch fast-path changes semantics for ambiguous names.
  - Mitigation: enable fast-path only for safe/explicit call shapes; keep existing path otherwise.
- Risk: over-optimization reduces maintainability.
  - Mitigation: incremental rollout with benchmark checkpoints and explicit documentation updates.
