# Galaaz 2.0 Required Improvements

This document captures required improvements identified in the code review, with one explicit scope rule:

- `shadow_bridge` is deprecated and scheduled for removal.
- We should not spend effort improving `shadow_bridge` internals.
- We should prioritize migration and cleanup work that removes `shadow_bridge` dependencies from active code paths.

## Scope and Direction

Galaaz 2.0 should focus on hardening the NewBridge path (`new_bridge` + `new_bridge_adapter`) and reducing legacy compatibility complexity. Any item that only improves deprecated `shadow_bridge` behavior is intentionally out of scope.

## Required Improvements

### 1) Thread-safe handle generation in `R::Support`

Current variable-name generation (`g2_v...`) uses a shared mutable counter without synchronization.

- File: `lib/R_interface/rsupport.rb`
- Risk: concurrent threads can generate duplicate names.
- Required improvement: protect counter increments with a `Mutex` (or equivalent atomic strategy).

Why this matters:
- Callbacks run in separate Ruby threads in NewBridge.
- Duplicate R handles can cause incorrect reads/writes and difficult-to-debug race conditions.

### 2) Tighten broad error fallback in `NewBridgeAdapter#eval_r`

`eval_r` currently rescues R process errors and retries in side-effect mode based on broad substring matches.

- File: `lib/R_interface/new_bridge_adapter.rb`
- Risk: unrelated R errors can be incorrectly swallowed if they include matching text.
- Required improvement: narrow matching to explicit gatekeeper error signatures (more strict predicate).

Why this matters:
- Prevents masking real failures.
- Improves correctness and observability during migration hardening.

### 3) Remove unconditional legacy bridge loading from active boot path

`r.rb` currently loads legacy bridge code early even when NewBridge is the default path.

- File: `lib/R_interface/r.rb`
- Risk: legacy-only dependencies and startup side effects are pulled into non-legacy usage.
- Required improvement: avoid loading legacy bridge code unless explicitly selected, or remove it entirely during deprecation cleanup.

Why this matters:
- Reduces startup risk and environment coupling.
- Aligns runtime behavior with the NewBridge-first architecture.

### 4) Replace text parsing of scalar output with structured result protocol

Some vector/data paths parse textual output (`"[1] ..."`), which is fragile.

- File: `lib/R_interface/rvector.rb`
- Risk: formatting changes or noisy output can break parsing.
- Required improvement: use `eval_r_with_result` envelope-based reads for scalar/type/length operations where possible.

Why this matters:
- NewBridge already exposes structured payloads.
- Structured parsing is more robust than output-string parsing.

### 5) Complete or remove comparator stub in `R::Vector`

`<=>` is currently a placeholder.

- File: `lib/R_interface/rvector.rb`
- Risk: undefined comparison semantics with surprising behavior in Ruby collection operations.
- Required improvement: either implement comparison semantics or raise `NotImplementedError` explicitly.

Why this matters:
- Avoids silent incorrect behavior.
- Makes contract clear to users.

### 6) Make data transfer paths more efficient (high impact)

Current `pull_dataframe` and vector pull helpers rely on many per-element bridge round-trips.

- File: `lib/R_interface/new_bridge_adapter.rb`
- Risk: major performance bottleneck for medium/large vectors and data frames.
- Required improvement: implement/expand bulk transfer paths for columns/vectors via gatekeeper protocol instead of per-cell/per-element `eval_r` loops.

Why this matters:
- This is one of the highest-impact improvements for real workloads.
- Reduces latency and CPU overhead on both Ruby and R sides.

### 7) Stabilize and simplify require graph in `r.rb`

There are duplicated requires and legacy ordering baggage.

- File: `lib/R_interface/r.rb`
- Risk: maintenance confusion and accidental coupling.
- Required improvement: remove duplicate requires and keep loading order minimal and explicit for NewBridge path.

Why this matters:
- Cleaner bootstrap path.
- Easier long-term maintenance during legacy removal.

### 8) Standardize platform-independent R library installation path

The package install helper currently uses a Linux-specific default path.

- File: `lib/R_interface/r.rb`
- Risk: portability issues across environments.
- Required improvement: derive install library path in a platform-aware way (or make default configurable with clear fallback).

Why this matters:
- Better cross-platform behavior.
- Less environment-specific setup friction.

### 9) Improve test execution defaults for NewBridge coverage

NewBridge suites are present but are not consistently part of default fast execution paths.

- Files: `bin/run_rspec`, `Rakefile`, test directory organization
- Risk: regressions can slip through if NewBridge-focused specs are not in routine runs.
- Required improvement: ensure NewBridge critical suites are included in standard CI/dev test commands, with clear separation for slow tests.

Why this matters:
- Migration safety depends on predictable coverage.
- Reduces false confidence from partial green runs.

### 10) Wire and enforce coverage reporting (if kept as dependency)

`simplecov` is in development dependencies but not clearly active in test bootstrap.

- Risk: no objective coverage signal during migration.
- Required improvement: either wire coverage reporting in spec bootstrap/CI or remove unused dependency to keep tooling honest.

Why this matters:
- Supports disciplined migration and refactoring decisions.
- Prevents dependency drift.

## Explicitly Out of Scope

The following are intentionally excluded from this document:

- Any refactor or hardening effort inside `lib/R_interface/shadow_bridge.rb`.
- Any optimization of deprecated FIFO-based callback plumbing used only by `shadow_bridge`.
- Any machine-specific path fixes that are relevant only to legacy bridge operation.

These should be superseded by removal of `shadow_bridge` from the codebase.

## Migration Note

Because `shadow_bridge` is deprecated, the recommended sequence is:

1. Remove active dependencies on `shadow_bridge` from default runtime paths.
2. Harden NewBridge correctness (thread-safety, strict error handling, structured decoding).
3. Improve NewBridge data transfer performance.
4. Consolidate test defaults around NewBridge and enforce coverage.
5. Remove `shadow_bridge` and related dead compatibility code.
