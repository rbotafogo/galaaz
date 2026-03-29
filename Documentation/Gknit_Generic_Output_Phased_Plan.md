# gknit Generic Output Phased Plan

## Objective

Ensure Galaaz/gknit behaves generically like GNU R + knitr for chunk evaluation and graphics capture:

- No engine-specific behavior (no ggplot-only logic).
- Any graphics system that draws to the active device must be captured and integrated.
- Fixes must be regression-protected by fast specs under `specs/` (not `new_bridge_specs/`).

## Global Rules (Non-negotiable)

- [x] Use `specs/` for all new tests related to this plan.
- [x] Before implementing any item marked "Needs Discussion", discuss and agree first.
- [x] If any proposed implementation is non-generic or resembles a kludge, STOP and discuss.
- [x] Keep changes minimal and directly tied to agreed phase scope.
- [x] No "silent semantic changes" without explicit review.

## Phase 0 - Alignment and Contracts — **COMPLETE (approved as-is)**

**Status:** Approved 2026-03-29. No further discussion required for items below before Phase 1–4 implementation.

### Scope

Define explicit behavioral contracts before coding.

### Approved contracts (summary)

#### 1) Callback return contract (transport vs semantic value)

- **Transport ACK:** Callback `RET` payload is transport-only and numeric (`"1"` success, `"0"` failure) so the gatekeeper can parse it safely.
- **Semantic callback value:** Passed separately via shared R-side storage (namespaced), then read and cleaned up by the caller stub.
- **Rule:** No semantic coercion in the transport layer.

**Acceptance:** Ruby callback semantics are never inferred from numeric ACK alone; semantic value round-trip is testable.

#### 2) `.GlobalEnv` usage policy

- Allowed only through a **single namespaced container**, e.g. `.GlobalEnv$.galaaz_bridge_env` (exact name TBD in implementation but must be one container).
- Keys must include **session + call id** when transient.
- Every transient key must be **cleaned up** on success and on error paths.
- **No** scattered `.GlobalEnv$foo` assignments for per-call values.

**Acceptance:** Code review can find all bridge temp state under one tree; no orphan globals after callback completion.

#### 3) gknit graphics capture contract (generic)

- Capture is **device-driven**, not object-class-driven.
- Any R graphics that draw on the **active device** (base, grid, ggplot2, lattice, etc.) must be capturable without package-specific branches in the engine core.

**Acceptance:** Phase 3 tests cover multiple plotting styles; engine logic does not branch on `class(x)` for ggplot vs others.

#### 4) Chunk option semantics contract

- `eval`, `echo`, `include`, `message`, `warning` follow **knitr** semantics.
- Logical **`NA`** means **inherit default**, never silently treated as `false`.
- HTML/MD output must reflect **evaluated** output; raw unevaluated chunk text where output was expected is a **failure** unless options explicitly request that behavior.

**Acceptance:** Fixture specs prove `NA` inheritance and echo/include/eval combinations.

#### 5) Test placement contract

- All tests for this plan live under **`specs/`** (fast suite).
- **`new_bridge_specs/`** is not used for these new regressions.
- Each phase adds tests **with** the change, not deferred.

**Acceptance:** New files appear under `specs/` only; CI or local `rspec specs/...` covers them.

### Phase 0 deliverables

- [x] Written contract summary in this document.
- [x] Acceptance criteria per contract item (see above).

### Former “needs discussion” — **resolved**

- [x] Callback result transport: ACK vs semantic value (see §1).
- [x] `.GlobalEnv`: namespacing and cleanup (see §2).
- [x] gknit graphics: device-driven, engine-agnostic (see §3).
- [x] Chunk output in HTML/MD and logical `NA` (see §4).

---

## Phase 1 - Callback Path Hardening (Adapter + Session Client)

### Scope

Stabilize callback argument/return handling without overfitting to any single caller.

### Implementation Checklist

- [x] Finalize and implement callback payload format for argument transport.
- [x] Finalize and implement callback return transport semantics (ACK/value boundaries).
- [x] Ensure callback registrations are reused safely when intended.
- [x] Ensure `.GlobalEnv` interactions are namespaced and cleaned up (if used).

**Implemented (2026-03-29):**

- Semantic callback results for `register_callback_proc_stub` are stored under `.GlobalEnv$galaaz_bridge_env` with keys `r_<session_key>_<call_id>` (session key is alphanumeric/underscore-safe), then removed after read in the R stub.
- `SessionClient` sends strtod-safe RET payloads: `register_callback_proc_stub` ends with `nil` → ACK `"1"`; direct `register_callback` blocks may still return a **Numeric** for legacy tests (e.g. nested depth-5 hardening).

### Test Checklist (`specs/`)

- [x] Scalar callback arg coverage: character, integer, double, logical, NA.
- [x] Non-scalar callback arg coverage: vector/list/data.frame as boxed objects.
- [x] Multi-call callback reuse coverage.
- [x] Return-path correctness coverage (no accidental coercion regressions).
- [ ] Basic concurrent callback isolation coverage (deferred: optional stress; not required for Phase 1 exit).

### Tests added

- `specs/phase1_callback_bridge_spec.rb` (included from `specs/all.rb`)

### Exit Criteria

- [x] All phase specs pass reliably (`specs/phase1_callback_bridge_spec.rb`; `new_bridge_specs/integration_phase5_3_*` still pass).
- [x] No open "Needs Discussion" items in Phase 1.

---

## Phase 2 - gknit Chunk Semantics and Output Correctness

### Scope

Ensure chunk evaluation/output semantics match knitr expectations.

### Implementation Checklist

- [ ] Validate/fix `eval`, `echo`, `include`, `message`, `warning` handling with logical `NA` inheritance.
- [ ] Ensure code and output blocks are rendered correctly in generated markdown/html.
- [ ] Remove/avoid any object-class-specific rendering shortcuts.

### Test Checklist (`specs/`)

- [ ] Fixture: text-only ruby chunk output appears in markdown/html.
- [ ] Fixture: `echo=FALSE`, `include=FALSE`, `eval=FALSE` behaviors.
- [ ] Fixture: `NA`-driven inheritance behavior for chunk options.
- [ ] Fixture: no raw unevaluated code leakage where evaluated output is expected.

### Exit Criteria

- [ ] All phase specs pass.
- [ ] Chunk rendering is validated as generic and deterministic.

---

## Phase 3 - Generic Graphics Capture (Engine-Agnostic)

### Scope

Capture graphics based on device behavior, independent of plotting package/class.

### Implementation Checklist

- [ ] Keep capture flow device-centric (open device -> execute chunk -> capture output -> close device).
- [ ] Ensure figure artifact generation and inclusion are consistent.
- [ ] Ensure no ggplot/lattice/base-specific branching in engine core.
- [ ] Confirm helper function placement/scope strategy (if `.GlobalEnv` used, namespaced + safe).

### Test Checklist (`specs/`)

- [ ] Fixture: base graphics (`plot(...)`) captured and included.
- [ ] Fixture: grid graphics captured and included.
- [ ] Fixture: ggplot graphics captured and included.
- [ ] Optional fixture: lattice captured and included (if baseline dependencies available).
- [ ] Fixture: mixed chunk document (text + multiple plot systems) renders correctly end-to-end.

### Exit Criteria

- [ ] All supported plotting systems pass generic capture tests.
- [ ] No engine-specific kludges introduced.

---

## Phase 4 - Documentation, Cleanup, and Commit Strategy

### Scope

Finalize docs, commit in reviewable units, and preserve traceability.

### Checklist

- [ ] Update docs with final contracts and implementation notes.
- [ ] Keep generated artifacts commits intentional and explicitly scoped.
- [ ] Split commits by phase or coherent feature/test unit.
- [ ] Record residual risks and follow-up tasks.

### Exit Criteria

- [ ] Phased commits completed with passing targeted specs.
- [ ] Plan checklist fully checked or deferred items clearly documented.

---

## Open Discussion Backlog (Carry Forward)

Resolved in Phase 0: containment naming detail is “single container + session/call keys + cleanup”; numeric ACK-only transport; semantic value via namespaced storage.

Remaining optional topics (not blocking Phase 1):

- [ ] Exact **container name** in R (e.g. `.galaaz_bridge_env` vs `galaaz:::bridge_env`) — decide at implementation time with one-line doc update.
- [ ] Whether **additional** slow-suite integration tests (e.g. full `new_bridge_specs`) run in CI after `specs/` pass — tooling decision, not contract.

## Working Agreement During Implementation

- [x] If we discover any non-generic workaround, we pause and discuss before coding.
- [x] If scope expansion seems necessary, we pause and get explicit agreement first.

