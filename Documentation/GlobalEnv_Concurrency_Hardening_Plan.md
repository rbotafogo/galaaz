# GlobalEnv Concurrency Hardening Plan

Date: 2026-03-30

## Status (Current)

- **Phase 1 (guardrails):** **In progress**
  - Added fast guardrail spec `specs/globalenv_guardrail_spec.rb` to detect unapproved new `.GlobalEnv$... <-` writes (ShadowBridge excluded as obsolete path).
- **Phase 2 (session env API):** **Partially complete**
  - NewBridge bootstrap now defines session helpers:
    - `galaaz_ensure_session_env(session_id)`
    - `galaaz_assign_session(session_id, key, value)`
    - `galaaz_get_session(session_id, key)`
    - `galaaz_rm_session(session_id, key)`
  - Ruby adapter exposes wrappers:
    - `ensure_session_env`
    - `assign_session`
    - `get_session`
    - `rm_session`
  - Added fast coverage: `specs/session_env_bridge_spec.rb`.
- **Phase 3 (callback isolation):** **Partially complete**
  - Callback semantic return staging is session-first, with legacy global fallback for migration compatibility.
  - Callback temporary `g2_v*` handles now resolve via session env (`.galaaz_sessions`) in NewBridge path.
- **Phase 4 (semantic return isolation):** **Mostly complete**
  - Read/write path now uses session env only in NewBridge callback flow (legacy global fallback removed from adapter path).
- **Additional reduction completed**
  - Internal temporary assignments were reduced from global to local scope in:
    - `lib/R_interface/rsupport.rb` (internal eval temp assignment),
    - `lib/R_interface/robject.rb` (unboxing temp assignment),
    - `lib/R_interface/rvector.rb` (character extraction temp assignment).

## Objective

Prevent cross-thread/session contamination by minimizing mutable state in `.GlobalEnv`, while preserving bridge reliability and current API behavior.

This plan treats the following as non-negotiable:

1. Request-specific data must not be written to process-global `.GlobalEnv`.
2. If global helpers are needed, they must be immutable/idempotent.
3. Errors at the Ruby/R frontier must be deterministic and structured (no unbounded recursion, no hidden global races).

## Current Inventory (`lib/` only)

### A) Global helper registration (generally acceptable if idempotent)

- `lib/R_interface/rdevice.rb`
  - `.GlobalEnv$evaluate_plot_snapshot <- function(...)`
  - `.GlobalEnv$galaaz_save_plot <- function(...)`
- `lib/gknit/knitr_engine.rb`
  - `.GlobalEnv$knitr_dev2ext`
  - `.GlobalEnv$g_simpleMessage`
  - `.GlobalEnv$g_simpleWarning`
  - `.GlobalEnv$evaluate_plot_snapshot`
  - `.GlobalEnv$save_recorded_plot`
  - `.GlobalEnv$knitr_wrap`
  - `.GlobalEnv$showtext`
- `lib/R_interface/new_bridge_adapter.rb`
  - `missing_arg` helper registration in `.GlobalEnv`
  - `awt` helper registration in `.GlobalEnv`

Risk level: **low/moderate**, assuming these are immutable and same-body definitions.

### B) Mutable runtime/request state in `.GlobalEnv` (must be reduced)

- `lib/R_interface/rsupport.rb`
  - `assignment = ".GlobalEnv$#{var_name} <- ..."`
  - setter path for `R.var = rhs` writes directly to `.GlobalEnv`
  - callback proc plumbing assigns temporary handles in `.GlobalEnv`
- `lib/R_interface/robject.rb`
  - temporary eval assignments via `.GlobalEnv$#{var}`
- `lib/R_interface/rvector.rb`
  - temporary extraction assignment `.GlobalEnv$#{var_name} <- ...`
- `lib/R_interface/new_bridge_adapter.rb`
  - callback arg handles assigned in `.GlobalEnv`
  - semantic return env container: `.GlobalEnv$galaaz_bridge_env` (namespaced, but still process-global)
- `lib/R_interface/shadow_bridge.rb`
  - extensive global-handle assumptions/rewrites (`.GlobalEnv$g2_v*`)

Risk level: **high** in concurrent callers sharing one R process.

## Target State

### Scope model

- Keep **immutable helper functions** in a bootstrap namespace (preferably one dedicated env), not scattered globals.
- Move **all mutable/transient objects** to a **session-scoped environment** owned by the bridge session.
- Keep `.GlobalEnv` as a compatibility façade only where unavoidable.

### Recommended environments

- `galaaz_boot_env` (immutable helpers)
- `galaaz_session_env_<session_id>` (mutable request/session state)
- optional `galaaz_callback_env_<session_id>` (callback temp handles)

## Phased Plan

### Phase 1 - Inventory lock + guardrails

1. Add a policy doc section to developer docs:
   - no mutable `.GlobalEnv` writes in new code.
2. Add a lightweight test that scans for new `.GlobalEnv$... <-` writes in modified files and fails if unapproved.

Exit:

- New writes require explicit annotation and review.

Current status:

- Guardrail spec added and enforced in fast suite.

### Phase 2 - Session environment API in bridge

1. Introduce bridge helpers:
   - `ensure_session_env(session_id)`
   - `assign_session(session_id, key, value_expr)`
   - `get_session(session_id, key)`
   - `rm_session(session_id, key)`
2. Route transient `g2_v*` assignments through session env by default.

Exit:

- Temporary handles no longer rely on `.GlobalEnv`.

Current status:

- Session environment helper API implemented (bootstrap + adapter wrappers).
- Temporary handles are migrated only for selected paths; callback arg handles remain compatibility-global.

### Phase 3 - Callback isolation

1. Move callback argument handle assignment (`assign(h, args[[i]], ...)`) to callback/session env.
2. Keep callback command execution deterministic by evaluating against that env + explicit parent.

Exit:

- Two concurrent callback flows cannot overwrite each other’s handles.

Current status:

- Semantic callback return values are session-scoped.
- Callback argument handles (`g2_v*`) are session-scoped in NewBridge path by reusing gatekeeper session env registry (`.galaaz_sessions`).

### Phase 4 - Semantic return isolation

1. Replace `.GlobalEnv$galaaz_bridge_env` with session-specific semantic env.
2. Keep old global path as compatibility fallback for one migration window only.

Exit:

- Semantic return values are session-scoped.

Current status:

- Session staging and retrieval implemented in callback path.
- Legacy `.GlobalEnv$galaaz_bridge_env` fallback removed from NewBridge callback path.

### Phase 5 - Helper consolidation

1. Move helper registration to a single bootstrap function:
   - idempotent definitions in `galaaz_boot_env`
2. `rdevice`/`gknit` consume helpers from that env instead of redefining.

Exit:

- No duplicate helper definition drift.

### Phase 6 - ShadowBridge deprecation and removal path

ShadowBridge is considered obsolete and is out of scope for `.GlobalEnv` concurrency hardening.

1. Mark ShadowBridge as deprecated/obsolete in code comments and docs.
2. Keep only minimal compatibility behavior (no new feature work, no concurrency guarantees).
3. Plan full removal in a later cleanup cycle once NewBridge coverage is complete.

Exit:

- ShadowBridge clearly documented as obsolete and excluded from hardening scope.

## Test Strategy

### Fast tests (`specs/`)

1. Two-thread collision test:
   - both threads assign/eval similarly named temporary symbols
   - verify no cross-read contamination.
2. Callback isolation test:
   - parallel callbacks with same argument names in separate sessions.
3. Regression test:
   - no stack overflow/unbounded recursion on unboxing paths.

### Slow tests (`slow-specs/`)

1. Sustained concurrency:
   - N threads/fibers with repeated bridge calls + callback returns.
2. Multi-session long-run:
   - ensure no leaked symbols across sessions.

## Acceptance Criteria

1. Active fast suite passes with added concurrency isolation tests.
2. No mutable request-state writes to `.GlobalEnv` in NewBridge path.
3. Existing user-facing APIs continue to work unchanged.
4. Errors remain structured (`RProcessError` / bridge errors), with no raw process crashes from scope collisions.

## Proposed Execution Order

1. Phase 2 (session env API)  
2. Phase 3 (callback isolation)  
3. Phase 4 (semantic return isolation)  
4. Phase 5 (helper consolidation)  
5. Phase 6 (ShadowBridge deprecate/remove path)

This order closes the highest concurrency risk first, with minimal surface churn.
