# Plan: Scoped symbol-facing DSL (`R[:x]` default, refinements opt-in)

This document proposes an **evolution of Galaaz’s Ruby-facing API** so that **elegant symbol-based R expressions** remain available **without globally monkey-patching `Symbol`** by default. It is a **design and migration plan** for maintainers and contributors; it is not yet an implementation checklist unless adopted.

---

## 1. Problem

Today, Galaaz (as used in several integrations) extends **`Symbol`** so that unknown method calls are interpreted as R-oriented expressions (via `method_missing` and related machinery—see `lib/R_interface/ruby_extensions.rb` and related files).

That design has **high leverage** for a terse DSL but **process-wide side effects**:

1. **Any** code that does `some_symbol.arbitrary_name` where `arbitrary_name` is not a core `Symbol` API may be **reinterpreted** as an R call after Galaaz loads.
2. **Load order** becomes critical. Real examples observed in application code:
   - **Sinatra + Mustermann** resolve `Mustermann[:sinatra]` as a method call on the symbol `:sinatra`; after Galaaz loads, that path can break routing in non-obvious ways.
   - **ActiveRecord on JRuby** can interact badly with **ActiveSupport::Notifications** fanout **after** Galaaz is loaded in the same process (symptoms include failures inside `active_support/notifications/fanout.rb` during SQL instrumentation). Application-level workarounds (e.g. skipping `sql.active_record` wrapping) are **symptoms**, not a cure for global `Symbol` patching.
3. **Debugging** becomes harder: “something weird with a symbol” may be Galaaz, the host framework, or both.

The issue is not “symbols as a notation,” it is **`Symbol` as the global hook**.

---

## 2. Goals

| Goal | Detail |
|------|--------|
| **Safety by default** | Fresh integrations (web apps, gems, mixed stacks) should not load a global `Symbol#method_missing` unless explicitly opted in. |
| **Preserve elegance** | Keep a **short, readable** surface for column names and R-like chains. |
| **Power user escape hatch** | Allow **opt-in** `:x.foo`-style syntax for scripts and advanced users who understand Ruby **refinements** and lexical scope. |
| **Migration** | Existing scripts and docs should have a **clear, staged** path off the global patch. |
| **JRuby-first** | Any solution must be validated on **JRuby** (Galaaz 2.0’s primary Ruby). |

Non-goals for this plan:

- Rewriting the entire R bridge or dplyr-style APIs in one step.
- Removing all use of symbols inside Galaaz internals where they do not patch the core class.

---

## 3. Proposed solution (two tiers)

### 3.1 Tier A — **Default public API: explicit reference wrapper** (`R[:x]` / `R.ref`)

Introduce (or elevate to **primary** in docs) a **small proxy object** that **wraps** a symbol (or string) and forwards unknown methods to the existing R expression machinery **without** changing `Symbol` globally.

**Illustrative API** (exact names are open to bike-shedding):

```ruby
# Preferred default style (new / migrated code)
R[:mpg].mean
R[:cyl].n_distinct
R[:mtcars][:mpg]   # if chaining matches current semantics

# Optional alias
R.ref(:mpg).mean
```

**Properties:**

- **Obvious** at call sites: “this is Galaaz.”
- **Grep-friendly** and easy to teach.
- **No collision** with `Mustermann[:sinatra]` or other `[:foo]` lookups that return classes—those are not `R[...]` unless `R` is shadowed (document namespace hygiene).

**Implementation sketch:**

- A class e.g. `Galaaz::SymbolRef` (or `R::Ref`) holding `@name` (`Symbol`/`String`).
- `method_missing` / operators live on **the ref class**, not on `Symbol`.
- Construction only via **`R[...]`** or **`R.ref(...)`** on the existing `R` module.

### 3.2 Tier B — **Opt-in: refinements** (`using Galaaz::SymbolDSL`)

For users who want **`:mpg.mean`** in a **bounded** scope:

```ruby
module MyNotebook
  using Galaaz::SymbolDSL

  def run
    :mpg.mean  # refined Symbol in this file’s scope (per Ruby refinement rules)
  end
end
```

**Properties:**

- **Lexical scoping** (`using`): other files and the standard library keep stock `Symbol` behavior **unless** they also `use` the refinement.
- **Explicit consent**: “I know what refinements do.”

**Caveats to document:**

- Ruby **`using`** is **per file** (and transitive rules are easy to get wrong); we should link to official docs and provide **copy-paste patterns** (single-file scripts vs. Rails autoload).

**Implementation sketch:**

- Move (or duplicate) the current `Symbol` hooks into `refine Symbol do … end` inside `module Galaaz::SymbolDSL`.
- **Do not** apply the refinement globally.

---

## 4. Global `Symbol` patching: deprecation path

### 4.1 Target end state

- **Default:** global **`Symbol#method_missing` (and related) not installed** when `require "galaaz"`.
- **Opt-in legacy:** e.g. `require "galaaz/global_symbol"` or `Galaaz.enable_global_symbol_dsl!` or `ENV["GALAAZ_GLOBAL_SYMBOL_DSL"]` for existing scripts that cannot migrate immediately.

### 4.2 Staged rollout (suggested)

1. **Phase 0 — Document** this plan and add examples for `R[:x]` + `using` to the manual / wiki.
2. **Phase 1 — Implement** `R[:x]` / `R.ref` and test parity with representative dplyr-style examples.
3. **Phase 2 — Introduce** `Galaaz::SymbolDSL` refinement module; test on JRuby.
4. **Phase 3 — Deprecation warning** when global symbol DSL is active (single clear message pointing to `R[:x]` and refinements).
5. **Phase 4 — Flip default** (global off by default); legacy require/env for old behavior.
6. **Phase 5 — Remove** global patch in a major version once downstreams have migrated (timeline TBD).

Exact phase boundaries can be adjusted based on semver policy and user feedback.

---

## 5. Documentation and ergonomics

- **Manual / README:** lead with **`R[:x]`**; put refinements under “Advanced”; put global legacy under “Deprecated / compatibility.”
- **Examples directory:** migrate high-visibility samples to **`R[:x]`** first.
- **Error messages:** if someone uses `:col.foo` without refinement and without global mode, optionally detect common patterns and suggest `R[:col].foo` (heuristic, optional).

---

## 6. Testing matrix (minimum)

| Scenario | JRuby | Notes |
|----------|-------|--------|
| `R[:x]` chains vs current global symbol behavior | ✓ | Parity tests on a fixed set of expressions. |
| Sinatra app: Mustermann routes + `require "galaaz"` | ✓ | With **global patch off**, routing must work regardless of order. |
| ActiveRecord: queries after Galaaz load | ✓ | With **global patch off**, no need for app-level SQL notification hacks. |
| Refinement: `using Galaaz::SymbolDSL` in one file only | ✓ | Confirm other files unaffected. |
| Legacy global mode | ✓ | Regression suite for existing scripts. |

---

## 7. Relation to application workarounds

Downstream projects (e.g. FinTracker Lite) have added **process-specific** mitigations:

- Lazy `require "galaaz"` to preserve Mustermann compile order.
- Skipping `sql.active_record` notification wrapping to avoid fanout errors after Galaaz loads.

**Adopting this plan in Galaaz** should **reduce** the need for such workarounds over time, especially when **global `Symbol` patching is off**. Until then, applications should keep their mitigations documented locally.

---

## 8. Open questions

1. **Naming:** `R[:x]` vs `R.ref(:x)` vs `G.ref(:x)`—consistency with existing `R.c`, `R.eval`, etc.
2. **Arity and dplyr NSE:** ensure ref objects compose identically with existing NSE helpers.
3. **Performance:** one extra object allocation per symbol link—measure in hot paths if needed.
4. **Graal / legacy paths:** confirm out of scope for 2.0 or gate legacy docs.
5. **Semver:** whether flipping the default global patch is **major-only** (recommended).

---

## 9. Summary

| Approach | Audience | Global `Symbol` patch |
|----------|----------|------------------------|
| **`R[:x]` / `R.ref`** | Default for apps and libraries | **Not required** |
| **`using Galaaz::SymbolDSL`** | Notebooks, advanced users | **Not required** |
| **Legacy global mode** | Existing scripts during migration | **Opt-in only** (target) |

This split preserves **most of the notational elegance** while making **safety the default** and **explicit consent** the rule for the highest-risk behavior.

---

## 10. References (internal / external)

- Ruby refinements: [Ruby Language Reference — Refinements](https://docs.ruby-lang.org/en/master/syntax/refinements_rdoc.html) (verify version used with JRuby).
- Galaaz symbol extensions (current): `lib/R_interface/ruby_extensions.rb` (and related).
- Related ecosystem issues discussed in downstream docs (e.g. FinTracker `Documentation/GALAAZ_INTEGRATION.md`)—informative, not normative for this repo.

---

*Document status: **proposal**. Revise or supersede as the project decides.*
