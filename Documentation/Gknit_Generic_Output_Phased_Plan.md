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

### Subphase 2.0 - Baseline/Regression Checkpoint (COMPLETE)

- [x] Add fast fixture spec for chunk output generation in HTML.
- [x] Verify `echo=NA` inheritance and baseline `eval/include` behavior as currently implemented.
- [x] Lock a passing checkpoint commit before semantic tightening.

**Notes:** checkpoint commit `0a3e97f` captures current deterministic behavior and prevents accidental regressions while exact semantics are implemented.

### Subphase 2.1 - Exact knitr `include=FALSE` Semantics (Option A)

**Goal:** align Ruby chunk engine with knitr contract: `include=FALSE` must still evaluate code and side effects while suppressing emitted chunk output.

#### Implementation Checklist (Subphase 2.1)

- [x] Ensure `eval` is the only execution gate.
- [x] Ensure `include=FALSE` does not suppress evaluation side effects.
- [x] Apply output suppression at rendering/emission stage only.
- [x] Keep behavior generic (no class/package-specific special cases).

#### Test Checklist (Subphase 2.1)

- [x] Update fixture expectation: state mutation from `include=FALSE, eval=TRUE` is visible in later chunk.
- [x] Keep assertion that hidden chunk output is not rendered in HTML.
- [x] Re-run focused specs and full `specs/` suite.

#### Exit Criteria (Subphase 2.1)

- [x] Exact knitr `include=FALSE` semantics verified by fast specs.
- [x] No regressions in existing callback/chunk suites.

**Implemented (2026-03-29):**

- `exec_ruby` now reads knitr option booleans directly from the options list on the R side (`options[['...']]`) to avoid bridge-wrapper ambiguity.
- Execution gating uses `eval` only; `include` no longer blocks execution.
- `knitr_engine` suppresses emission when `include=FALSE` after evaluation/side effects, matching knitr semantics.
- `specs/phase2_gknit_chunk_output_spec.rb` verifies the same markers for `html_document` and `github_document`; `pdf_document` skips if LaTeX is missing, otherwise checks a valid PDF (full string parity when `pdftotext` is installed):
  - `eval=FALSE` does not execute side effect (`PHASE2_EVAL_FALSE_STATE=0`)
  - `include=FALSE, eval=TRUE` executes side effect (`PHASE2_INCLUDE_FALSE_STATE=1`)
  - hidden chunk output is not emitted into the rendered artifact.

### Subphase 2.2 - Multi-format rendering (HTML + PDF + third format)

**Goal:** the same Ruby chunk semantics must hold when `gknit` targets different `rmarkdown` output formats—not only `html_document`.

**Formats (default set):**

1. `html_document` (already covered).
2. `pdf_document` — requires LaTeX on the host. **TinyTeX** (user install, no sudo): run `bin/install-tinytex` or the [official install script](https://github.com/rstudio/tinytex). The Phase 2 spec prepends `~/bin` and `~/.TinyTeX/bin` to `PATH` so `gknit` finds `pdflatex` even when the shell profile does not. If render fails (no LaTeX), that example **skips** with the error excerpt. **Full PDF string parity** with HTML/md needs **`pdftotext`** (`poppler-utils` on Debian/Ubuntu); otherwise the spec still passes on a valid PDF smoke check (signature + minimum size).
3. `github_document` — Pandoc Markdown output; no LaTeX; good third format for fast, portable checks.

#### Implementation Checklist (Subphase 2.2)

- [x] Extend Phase 2 fixture YAML to declare `html_document`, `pdf_document`, and `github_document` (minimal options).
- [x] Run `bin/gknit --output_format <format>` per format from `specs/` (same chunk body).
- [x] Assert presence/absence of the same semantic markers in each artifact (HTML / `.md` / PDF via `pdftotext` or printable scan, see spec).

#### Test Checklist (Subphase 2.2)

- [x] HTML: unchanged assertions.
- [x] PDF: valid PDF (`%PDF`, non-trivial size); **always** when LaTeX works; full chunk string checks when `pdftotext` works or uncompressed literals are visible; **skip** only if `pdf_document` render fails (no LaTeX).
- [x] GitHub doc: `.md` contains expected output strings and excludes hidden `include=FALSE` line output.

#### Exit Criteria (Subphase 2.2)

- [x] At least two formats always exercised without LaTeX (HTML + `github_document`); PDF runs when LaTeX is available (smoke always; deep text checks with poppler); skips only if LaTeX is missing.
- [x] Phase 2 “generic rendering” exit criterion below may be marked once this subphase is implemented (see wording there—no claim of byte-identical PDF across machines).

### Implementation Checklist

- [x] Validate/fix `eval`, `echo`, `include`, `message`, `warning` handling with logical `NA` inheritance.
- [x] Ensure code and output blocks are rendered correctly in generated markdown/html.
- [ ] Remove/avoid any object-class-specific rendering shortcuts.

### Test Checklist (`specs/`)

- [x] Fixture: text-only ruby chunk output appears in markdown/html.
- [x] Fixture: `echo=FALSE`, `include=FALSE`, `eval=FALSE` behaviors.
- [x] Fixture: `NA`-driven inheritance behavior for chunk options.
- [ ] Fixture: no raw unevaluated code leakage where evaluated output is expected.

### Exit Criteria

- [x] All phase specs pass (for current committed scope).
- [x] Chunk semantics are regression-tested across **`html_document` and `github_document`** with the same fixture and string expectations. **`pdf_document`** asserts a successful LaTeX build and valid PDF when TinyTeX/system TeX is installed; **full** PDF text assertions match HTML/md when **`pdftotext`** (poppler-utils) is available. Without LaTeX, the PDF example **skips**. Strict byte-identical determinism (timestamps, cross-machine PDF) remains out of scope unless explicitly added later.

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

