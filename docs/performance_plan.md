# Performance execution plan (new bridge)

This is the **step-by-step execution checklist** for the work outlined in [performance.md](./performance.md). Check items off as you complete them.

**Principles**

- **JRuby first** (primary runtime); MRI may follow later.
- **Fail-fast batching:** inside `R.batch`, the first failing sub-operation aborts the batch; **no** subsequent ops run. Semantics match sequential step-by-step execution on the success path; on failure, behavior matches having stopped before later calls.
- **Trust wrapper tags** from the bridge when present; keep `class(...)`-style probing only for missing or legacy envelopes (see [performance.md](./performance.md)).
- After **each phase**, run the regression commands and add or extend **RSpec** examples so behavior stays pinned.

**Reference benchmark script — DESeq2 airway (heuristic phase labels)**

File: `examples/bioconductor_deseq2_airway/deseq2_airway_galaaz.rb`

| Phase (heuristic) | Lines | Contents (informal) |
|-------------------|------:|---------------------|
| **Setup** | 3–14 | `library` / `data`, `DESeqDataSet`, formula, prefilter (`rowSums`, `counts`, subset) |
| **Compute** | 17–18 | `DESeq`, `results` |
| **Output / plot** | 20–33 | `puts` with embedded `R.*`, `head` / `as.data.frame`, `pdf` / `plotMA` / `dev.off` |

Use these labels when recording timings or documenting before/after medians; they are **not** enforced by the runtime.

**RSpec regression commands (default)**

- Full new-bridge–relevant run: `bin/run_all_rspec` (compiles gatekeeper, then `specs/` + `new_bridge_specs/`).
- Faster slice during tight loops: `bin/run_rspec` plus any paths you touched (see [testing.md](./testing.md)).

---

## Phase 1 — Result envelopes: stable `wrapper_tag` (+ `r_class`)

**Goal:** Every handle return from `eval_r_with_result` (and equivalent paths) includes metadata sufficient to choose a Ruby wrapper without an extra `class(...)` round-trip when the tag is present.

- [x] **Protocol / R side:** Define normalized tag set (e.g. `vector`, `data_frame`, `matrix`, `list`, `closure`, `environment`, `language`, `symbol`, `other`) and map from actual R types.
- [x] **Adapter / session:** Populate envelope fields in `lib/R_interface/new_bridge_adapter.rb`, `lib/new_bridge/session_client.rb` (and any sibling emitters).
- [x] **Ruby consumer:** Thread `wrapper_tag` (and `r_class`) through to object construction call sites that already use the envelope.

**Regression (RSpec)**

- [x] Run `bin/run_all_rspec` (or at minimum `bin/run_rspec specs/protocol_result_spec.rb` plus new_bridge eval / result specs if touched).
- [x] Add or extend specs that assert returned envelopes include `wrapper_tag` for representative evals (vectors, data frames, lists, closures as applicable).

---

## Phase 2 — `Object.build`: prefer envelope; probe only on unknowns

**Goal:** Hot path uses `Object.build(..., r_class:, wrapper_tag:)` (or equivalent); fallback class probing only when metadata is missing or explicitly legacy.

- [x] **API:** Implement constructor path that accepts envelope metadata in `lib/R_interface/robject.rb`.
- [x] **Callers:** Pass tag + class from envelopes; remove redundant probes on the happy path.
- [x] **Observability:** `R::Object.build_class_probe_count` / `R::Object.reset_build_counters!` count `class()` probes issued from `Object.build`.

**Regression (RSpec)**

- [x] Run `bin/run_all_rspec` (or `bin/run_rspec` over `specs/*semantics*`, `specs/unboxing*`, `specs/protocol_result_spec.rb`, `specs/new_bridge_*` as relevant).
- [x] Add specs that construction with a synthetic envelope + tag does **not** trigger a class probe (if testable via counter or mock), and that missing metadata still probes/falls back correctly.

**Performance note:** `R::Support.eval` / `exec_function` already passed `r_class` from the bridge envelope, so those paths did not call `class()` before Phase 2 either. Phase 2 adds (1) **probe-free** builds when `wrapper_tag` is non-`other` but `r_class` is absent, (2) **tag-first** wrapper choice (with a **formula** exception: `language` + `formula` class stays plain `R::Object`), and (3) a **counter** for remaining probes (e.g. `Object.build(handle)` without metadata). Large end-to-end gains expect Phase 3+ (dispatch, batching).

---

## Phase 3 — Dispatch: fast path for `R.foo(...)`; cache probes

**Goal:** Obvious module-style function calls skip unnecessary `is_field` / `is_func` work; ambiguous `obj.name` keeps probing; expand/strengthen probe cache.

- [x] **Fast path:** `lib/R_interface/rsupport.rb` — `R.foo(...)` already uses `exec_function` when `internal` is not an `R::Object` (documented explicitly).
- [x] **Cache:** Per `(handle, name)` FIFO cache (max 4096) for `dispatch_probe` results; `R::Support.dispatch_probe_cache_hits` / `dispatch_probe_cache_misses`, `reset_dispatch_probe_cache_stats!`, `clear_dispatch_probe_handle_cache!`. **Not** used for `R::Environment` receivers (mutable bindings / `rm()`).

**Regression (RSpec)**

- [x] Run `bin/run_rspec specs/r_object_send_dispatch_spec.rb specs/dispatch_probe_fallback_spec.rb specs/dispatch_probe_error_class_fallback_spec.rb` and full suite if time permits.
- [x] Add specs for fast-path vs ambiguous receiver behavior (no semantic change for valid programs).

---

## Phase 4 — Explicit `R.batch` (fail-fast, per-op envelopes)

**Goal:** `R.batch do ... end` queues compatible operations, sends **one** multi-op bridge request, returns **per-op** result envelopes on success. On first error: **fail-fast** (later ops not executed); surface error index / op identity for debugging. Same observable outcome as sequential calls when each step succeeds.

- [ ] **Protocol:** Multi-op request/response with ordered results and structured errors.
- [ ] **Ruby API:** `R.batch` block collector; document fail-fast semantics in code comments or [performance.md](./performance.md) if user-visible.
- [ ] **Tests:** Happy path (multiple ops), failure on op *k* (verify op *k+1* did not run), ordering.

**Regression (RSpec)**

- [ ] Run `bin/run_all_rspec`.
- [ ] New file e.g. `specs/r_batch_fail_fast_spec.rb` (or under `new_bridge_specs/` if integration-heavy) covering success, single-op failure, and ordering.

---

## Phase 5 — Instrumentation and benchmark guardrails

**Goal:** Repeatable signals: round-trip count, fallback class probes, dispatch probe hits/misses; optional segmented timings for DESeq2 heuristic phases.

- [ ] **Counters:** Wire optional debug hooks (env or config flag) without affecting default hot-path cost noticeably.
- [ ] **Micro-benchmark or spec:** Setup vs warm-loop (same process) script or tagged example; record medians in [performance.md](./performance.md) or a short `docs/` benchmark note.
- [ ] **Acceptance tracking:** Compare to baseline (startup, setup, compute, output/plot — inferred from line table above).

**Regression (RSpec)**

- [ ] Run `bin/run_all_rspec`.
- [ ] Add specs that enable counter mode in test and assert monotonic or expected relationships (e.g. batch reduces round-trip count vs N singles for a fixed script), without flaking on absolute timing.

---

## Phase 6 — Batching-friendly `puts` / string interpolation (optional; after `R.batch` is stable)

**Goal:** Coalesce resolution of `R.*` sub-expressions used in `puts` (or similar) where order and side effects remain deterministic — see [performance.md](./performance.md) track 7.

- [ ] **Design:** Opt-in first (e.g. flag), then optional auto-batch micro-window if desired.
- [ ] **Implementation:** `lib/R_interface/rsupport.rb` (and protocol as needed).

**Regression (RSpec)**

- [ ] Run `bin/run_all_rspec` and any `slow-specs` that cover `puts` + R if applicable.
- [ ] Add regression examples for output equality with non-batched path.

---

## Phase 7 — Collapse safe expression chains (only if benchmarks still warrant)

**Goal:** Fewer evals for idioms like `counts` → `rowSums` → compare, or subsetting with `:all`, **only** where composed R is provably equivalent.

- [ ] **Identify** hot chains from DESeq2-style scripts and benchmarks.
- [ ] **Implement** via existing APIs or thin helpers; no user-facing semantic drift.

**Regression (RSpec)**

- [ ] Run `bin/run_all_rspec`.
- [ ] Add specs comparing results of collapsed vs stepwise evaluation on fixed fixtures.

---

## Phase 8 — Prepared expression / function cache (R side)

**Goal:** `prepare` / `call_prepared` (or equivalent): parse/bind once, call many with arguments only.

- [ ] **Protocol + R helper** for prepared handles.
- [ ] **Ruby** call sites for repeated patterns (summaries, small transforms).

**Regression (RSpec)**

- [ ] Run `bin/run_all_rspec`.
- [ ] Integration specs: prepare → multiple calls match naive repeated eval for same inputs.

---

## Phase 9 — Session warmup and reuse

**Goal:** Long-lived sessions, optional preload of common libraries/symbols; reuse stable handles where safe.

- [ ] **Bootstrap** paths documented and implemented without breaking single-shot scripts.
- [ ] **Notebook / REPL** workflows benefit measurably.

**Regression (RSpec)**

- [ ] Run `bin/run_all_rspec` and any session lifecycle specs (`specs/session_env_bridge_spec.rb`, `new_bridge_specs/*session*` as applicable).
- [ ] Specs for warmup idempotency and no leak of stale handles across intentional session reset.

---

## Phase 10 — Compact envelopes, wrapper reuse, JRuby/GC awareness

**Goal:** Lower per-op serialization and allocation churn; evaluate JVM flags / hot paths before exotic optimizations ([performance.md](./performance.md) track 10).

- [ ] **Envelopes:** Smaller payloads for scalar/meta responses where safe.
- [ ] **Wrappers:** Reuse for stable handles where correctness allows.
- [ ] **Document** recommended JRuby flags (reference `bin/galaaz_jruby_env.inc.sh` / [testing.md](./testing.md)).

**Regression (RSpec)**

- [ ] Run `bin/run_all_rspec`.
- [ ] Stress or allocation-smoke specs if added; otherwise rely on full suite + benchmark note.

---

## Final acceptance checklist

- [ ] **Functional:** Existing tests pass; `examples/bioconductor_deseq2_airway/deseq2_airway_galaaz.rb` still runs successfully.
- [ ] **Performance:** Update measured medians vs baseline; initial targets in [performance.md](./performance.md) are aspirational — record what was achieved.
- [ ] **Observability:** Counters show reduced fallback class probes and dispatch probes vs baseline when comparing the same benchmark configuration.

---

## Risk reminders (from [performance.md](./performance.md))

- Wrapper misclassification → strict tests per tag + fallback for unknowns.
- Dispatch fast-path → only safe call shapes; preserve ambiguous `obj.name` behavior.
- Large refactors → land in phases with benchmark checkpoints after Phases 2–5.
