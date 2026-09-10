# Plan: Galaaz on Omarchy (TryOmarchy → menu overlay → upstream PR)

Status: **Phases A–C landed**; **`galaaz omarchy` (gem 2.1.7+)** installs the menu overlay from the gem (optional `--from-git`). Next: finish Phase D/E TryOmarchy dogfood (core **and Ledger**), then Phase F upstream **core-only** PR.  
Audience: Galaaz maintainers  
Related: [README.md](../README.md) (gem + gatekeeper install), [docker/cold-install-cruby](../docker/cold-install-cruby) (CRuby stranger-machine proof), [blogs/README.md](../blogs/README.md) (blog sources shipped in the gem), [script/omarchy/README.md](../script/omarchy/README.md)

---

## Goal

A user on Omarchy can choose **Install → Development → Galaaz** (R-on-Rails) and get:

- CRuby via **mise** (same path Omarchy already uses for Rails)
- GNU R + minimum CRAN packages
- `gem install galaaz` + native **gatekeeper** build
- **Blog sources** on disk (the gem already packs `blogs/**`; HTML/PDF are built, not shipped)

Then we can open a **small** PR against [basecamp/omarchy](https://github.com/basecamp/omarchy). Until that PR exists — and **even after** it lands for add-ons — the menu is driven by a **user overlay** installed with:

```bash
gem install galaaz
galaaz setup                 # or let omarchy-install-galaaz do gem + setup + blogs
galaaz omarchy               # copy script/omarchy → ~/.local/bin + menu jsonc
# optional: galaaz omarchy install --from-git   # newer overlay than the gem
```

**TryOmarchy** ([tryomarchy.com](https://tryomarchy.com/), unofficial) is the preferred dogfood machine: it is a disposable Windows app wrapping a full Omarchy VM. Delete the app data folder and reinstall to get a clean guest. That matches how we already use throwaway Docker for cold gem installs.

---

## Non-goals (this plan)

- Shipping Galaaz as an Omarchy **shell plugin** (QML). Plugins do not run install hooks or sudo.
- Making **JRuby** the Omarchy default. Omarchy’s Ruby is CRuby + mise. JRuby remains supported in Galaaz itself, not in the Omarchy catalog row.
- Installing Bioconductor, TinyTeX, Arrow, or the ledger app on **first** click. Those are **add-on profiles** (see below), installed after core Galaaz.
- Vendoring Galaaz source, blogs, or `r_on_rails_ledger` into the Omarchy git repo. Omarchy’s catalog row stays a thin wrapper; add-ons live in **Galaaz CLI + our jsonc overlay**. The first upstream PR (Phase F) is **core only**.

---

## Constraints (review bar)

Omarchy has no `CONTRIBUTING.md`. Merges are typically **DHH** (see Scala: [omarchy#2602](https://github.com/basecamp/omarchy/pull/2602), two files, +8/−2). Style is [AGENTS.md](https://github.com/basecamp/omarchy/blob/master/AGENTS.md) in that repo.

| Rule | Implication for us |
|------|-------------------|
| Tiny PR | Only `omarchy-install-dev-env`, `omarchy-remove-dev-env`, and menu JSONC rows |
| Helpers | `omarchy-pkg-add`, `omarchy-cmd-present` / `omarchy-cmd-missing`; `#!/bin/bash`; two spaces |
| Install rows | `when:` with a **negated** presence check so the row **hides** after install (same as Omarchy Rails). Prefer `test ! -f ~/.config/galaaz/profiles/…`. Older docs said `disabled:`; Omarchy now hides Install options instead of dimming them. |
| Remove rows | `when:` so the row hides if Galaaz core is absent |
| Omakase | “You can now run: …” one command, like `rails new myproject` |
| No clone | Cold machine: **no** `git clone` of Galaaz |
| Fast first run | Reuse `mise` Ruby binaries (`ruby.compile false` as Omarchy already sets for Rails) |

If first install takes tens of minutes or asks interactive CRAN questions, do not open the PR.

---

## Current Galaaz install (honesty)

Today a stranger machine still does roughly:

1. Ruby (JRuby **or** CRuby) + GNU R + C++ toolchain + **Rcpp**
2. `gem install galaaz`
3. `make -C "$(ruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path")/ext/new_bridge" all`
4. Blogs are **sources inside the gem**; rendering needs **gknit** + R packages (`knitr`, …) and is a **second** step

There is a CLI for this now (`bin/galaaz setup` / `blogs init` / `doctor` / `add` / **`omarchy`**). Omarchy dogfood uses that CLI plus TryOmarchy before any upstream PR.

Existing automated proof (Ubuntu, not Arch/Omarchy):

```bash
./docker/cold-install-cruby/run.sh          # smoke
./docker/cold-install-cruby/run.sh published-specs
```

Omarchy is **Arch**. Passing Ubuntu Docker is **necessary but not sufficient**. Phases B–E exist because of that gap.

---

## Success criteria (whole project)

| ID | Criterion |
|----|-----------|
| S1 | On a **clean TryOmarchy** guest, after `galaaz omarchy`, Install → Development → Galaaz (core) completes without a Galaaz git checkout |
| S2 | After install, `galaaz` (or documented equivalent) is on `PATH` and `R.c(1,2,3)` works |
| S3 | Blog **sources** exist under a documented directory (default `~/galaaz-blogs`) |
| S4 | Menu row is dimmed with ✓ (`disabled:`); Remove → Development → Galaaz uninstalls Galaaz without removing Omarchy’s Ruby/Rails |
| S5 | Wipe TryOmarchy data, reinstall the app, repeat S1–S4 (clean-room) |
| S6 | Optional later: upstream PR is three-file, matches Scala shape; gem on RubyGems is the version the installer uses |
| S7 | After core install, **Install → Development → Galaaz → …** add-ons (Arrow, Knit, TeX, Bio, Ledger) each do one job; ledger boots with `bin/dev` and a stress-test click |

---

## Phases

Do not start a later phase until the previous **exit tests** pass. Record date, host, and pass/fail in a short log at the bottom of this file (or a linked notes file) when you run them.

```
A  Productize Galaaz install     →  B  Tests on Linux we already have
   (core + `galaaz add`)
                                 →  C  Arch-shaped installer in this repo
                                 →  D  TryOmarchy + `galaaz omarchy` overlay
                                      (core row + add-on submenu)
                                 →  E  Reset loop (wipe VM, reinstall)
                                 →  F  Upstream PR = core only
                                      Add-ons stay overlay / `galaaz add` /
                                      `galaaz omarchy` (even if F merges)
```

---

## Phase A — Productize install in the Galaaz repo

**Why:** Omarchy will not merge a 200-line special snowflake. Galaaz must expose a boring CLI.

### A.1 Commands to add (names can change; behavior must not)

| Command | Behavior |
|---------|----------|
| `galaaz setup` | Locate gem dir; `make -C ext/new_bridge all`; fail loudly if `R`/`Rscript`/compiler missing |
| `galaaz blogs init [DIR]` | Copy `blogs/` from the **installed gem** to `DIR` (default `~/galaaz-blogs`). Also install `sty/galaaz.sty` beside that tree for PDF. Overwrite policy: refuse if DIR exists and is non-empty unless `--force` |
| `galaaz doctor` | Print Ruby engine, R version, gatekeeper binary present, `Rcpp` installed, blogs dir, sty, pdflatex, **which add-on profiles are present** |
| `galaaz add PROFILE` | Idempotent extra stack (see [Add-on profiles](#add-on-profiles-arrow-bio-tex-examples-ledger)). Refuses if core Galaaz is missing |
| `galaaz omarchy [install]` | Install Omarchy menu overlay from gem (`script/omarchy/` → `~/.local/bin` + extensions jsonc). Options: `--from-git [--ref REF]`. Also: `galaaz omarchy status` |

Optional: `galaaz blogs knit <name>` wrapping `gknit` on a copied blog (needs profile `knit`).

**Omarchy default Ruby:** CRuby 3.3+ via mise. `galaaz setup` must work under that Ruby (`GALAAZ_RUBY` / `bin/galaaz-ruby` already exist for checkouts; gem `galaaz` executable must work after `gem install`).

### A.2 CRAN set for “install Galaaz”

**Required on first Omarchy install** (non-interactive `Rscript`, `repos='https://cloud.r-project.org'`):

- `Rcpp` (gatekeeper)

**Required to *copy* blogs:** none beyond the gem files.

**Required to *knit* the six shipped blogs** (Phase D optional tier, not first click):

- `dplyr`, `knitr`, `rmarkdown` (same set as `docker/cold-install-cruby/install-and-smoke.sh` for specs)
- Per-blog extras as they fail (e.g. ggplot2 / RColorBrewer). Track them in a single `r_requires/` or installer list so Omarchy does not grow an unbounded `install.packages` wall.

**Not on first click** — `galaaz add` profiles: `arrow`, Bioconductor, TinyTeX, gem examples, ledger (see next major section).

### A.3 Mise

Omarchy already runs `mise use --global ruby@latest`. Galaaz does **not** need a custom mise plugin for the first PR.

If we later publish a mise tool named `galaaz`, it is a **follow-up**. This plan’s installer is:

```text
ensure ruby (mise) → ensure R (pacman) → gem install galaaz → galaaz setup → galaaz blogs init
```

### A.4 Exit tests (Phase A)

Run from a **checkout** after implementing the CLI (not yet Omarchy).

| Test | Command / check | Pass |
|------|-----------------|------|
| A-T1 | `galaaz setup` after `bundle exec` or local gem | gatekeeper built; exit 0 |
| A-T2 | `galaaz blogs init /tmp/galaaz-blogs-test` | six blog dirs present: `oh_my`, `gknit`, `galaaz_ggplot`, `manual`, `nse_dplyr`, `ruby_plot` (each with `.Rmd`) |
| A-T3 | Second `blogs init` without `--force` on same DIR | non-zero exit |
| A-T4 | `galaaz doctor` | non-empty R version; reports setup OK |
| A-T5 | Smoke: `ruby -e "require 'galaaz'; puts R.c(1,2,3)"` (or `galaaz` REPL equivalent) | prints vector; same idea as `docker/cold-install-cruby/smoke.rb` |
| A-T6 | `galaaz add knit` then `galaaz doctor` lists `knit` | R `knitr` namespace present |

---

## Add-on profiles (Arrow, Bio, TeX, examples, ledger)

**Why a second layer:** Omarchy’s first-click bar is “done in minutes, one `You can now run`.” Arrow compile, Bioconductor, TinyTeX, and a full Rails demo will fail that bar. After **core** Galaaz exists, the user extends the same machine with **named profiles**.

This is the Omarchy analogue of Rails: `rails new` is core; you add Sidekiq, Postgres, etc. later. Here: **Install Galaaz**, then **Install → Development → Galaaz → Ledger** (or `galaaz add ledger`).

### Design rules

1. **Core does not imply add-ons.** `galaaz` on PATH is enough for S1–S4.
2. **`galaaz add PROFILE` is the only installer logic.** Omarchy jsonc only launches that command in a terminal. No second copy of package lists in shell scripts.
3. **Idempotent.** Second `galaaz add arrow` is a no-op (exit 0).
4. **Guards.** Each profile writes `~/.config/galaaz/profiles/PROFILE` (or `galaaz doctor --json`) so menu `disabled:` / `when:` can test a **file**, not a 5-second Rscript on every menu open. `doctor` still verifies the real packages.
5. **Refuse without core.** `galaaz add` exits non-zero if gatekeeper / `Rcpp` missing.
6. **Remove Galaaz does not uninstall add-on R packages or TinyTeX** (too easy to wreck a scientist’s library). It removes the gem, blogs dir we created, and profile markers. Document that R packages remain. Optional `galaaz add PROFILE --purge` is a later foot-gun, not the Omarchy Remove row.
7. **Upstream PR stays core-only.** Add-on rows live in **our overlay** forever unless Omarchy later wants a submenu.

### Profiles

| Profile | CLI | What it installs | User can then |
|---------|-----|------------------|---------------|
| `knit` | `galaaz add knit` | CRAN: `dplyr`, `knitr`, `rmarkdown`, plus blog extras we pin (`ggplot2`, `kableExtra`, …) in one `r_requires/knit.txt` | Knit blog HTML (`gknit` / `galaaz blogs knit`) |
| `arrow` | `galaaz add arrow` | R `arrow` + `dplyr` via **LIBARROW_BINARY** (Apache version-matched prebuilt libarrow; `LIBARROW_BUILD=false`, `ARROW_USE_PKG_CONFIG=false` — do not compile Boost on Arch or link mismatched pacman arrow). CRuby: try `gem install red-arrow` (optional; needs Arrow GLib). JRuby: Arrow JARs + `JAVA_OPTS` nio opens | `Galaaz::ArrowIpc` / `R::Arrow.open_ipc` / `write_ipc`; `specs/arrow_*` |
| `tex` | `galaaz add tex` | Pandoc (pacman) + TinyTeX via existing `bin/install-tinytex` (user `~/.TinyTeX`, no sudo) | `gknit --output_format pdf_document` |
| `bio` | `galaaz add bio` | `BiocManager` + `DESeq2` + `airway` (the shipped example). **Slow.** Warn in the terminal before install | `examples/bioconductor_deseq2_airway` |
| `examples` | `galaaz add examples` | Copy gem `examples/` to `~/galaaz-examples` (same pattern as blogs). Does **not** pull Bio/Arrow; doctor warns if an example’s R pkgs are missing | `run_example` from that tree |
| `ledger` | `galaaz add ledger` | See [Ledger add-on](#ledger-add-on-r_on_rails_ledger) | `cd ~/r_on_rails_ledger && bin/dev` → http://localhost:3000 |

Suggested meta-profile (overlay only, not required): `galaaz add demo` = `knit` + `arrow` + `ledger` (no Bio, no TeX). That is the **pitch machine**.

### Ledger add-on (`r_on_rails_ledger`)

The ledger is a **separate repo**, not packed in the gem. Today it is a sibling checkout with `gem "galaaz", path: "../galaaz"`. Omarchy / pitch machines must use **RubyGems Galaaz** and a **clone**.

**Prerequisites already on Omarchy after core + Rails:** CRuby (mise), Bundler, SQLite, `bin/rails`. Ledger also needs **GNU R + gatekeeper** (core) and **Arrow** for the stress-test pitch (Local R → Arrow table → `R.quantile`). Docker dual-R engines stay **optional** (`bin/setup_docker_r_engines`); do not install Docker images in `galaaz add ledger`.

**`galaaz add ledger` should:**

1. Require profiles `arrow` (install it first if missing) — ledger runbook’s Local R path is Arrow + DSL.
2. `git clone` the public repo (URL we pin, e.g. `https://github.com/rbotafogo/r_on_rails_ledger.git`) to `~/r_on_rails_ledger` unless the directory already exists.
3. Ensure Gemfile is **standalone**: `gem "galaaz"` **without** `path:`. If we clone a branch that still has the path gem, the installer **rewrites** that one line (or we keep a `Gemfile.omarchy` in the ledger repo — prefer a supported Gemfile on `main` so we do not sed in production).
4. `bundle install` with mise Ruby; `galaaz setup` if the bundle’s galaaz gem lacks a built gatekeeper.
5. `bin/rails db:prepare` and `SEED_PROFILE=fast bin/rails db:seed` (not `wow` on TryOmarchy).
6. Write profile marker. Echo: `You can now run: cd ~/r_on_rails_ledger && bin/dev` then open http://localhost:3000 — portfolio → Run stress test.

**Honesty:** `path: "../galaaz"` remains the **developer** workflow on the workstation that has both trees. Omarchy is the **stranger** workflow. Do not teach Omarchy users to clone Galaaz source.

**Not in ledger add-on (first version):** `SEED_PROFILE=wow`, Docker R 3.6/4.3 images, JRuby.

### Menu overlay for add-ons

Core **Galaaz** becomes a **submenu** (no `action` on the parent). Children:

| Id | Kind | Guard |
|----|------|--------|
| `install.development.galaaz` | submenu | always |
| `install.development.galaaz.core` | action `omarchy-install-galaaz` | `disabled:` `omarchy-cmd-present galaaz` |
| `install.development.galaaz.knit` | action `galaaz add knit` | `when:` galaaz present; `disabled:` profile `knit` |
| `install.development.galaaz.arrow` | action `galaaz add arrow` | same pattern |
| `install.development.galaaz.tex` | action `galaaz add tex` | same |
| `install.development.galaaz.bio` | action `galaaz add bio` | same |
| `install.development.galaaz.examples` | action `galaaz add examples` | same |
| `install.development.galaaz.ledger` | action `galaaz add ledger` | same |
| `install.development.galaaz.demo` | optional | `galaaz add demo` |

Remove stays one row: remove **core** gem. Add-on submenu rows use `when: galaaz` so they vanish if core is gone (user reinstalls add-ons after a wipe).

Profile presence check for `disabled:` must be **fast**. Prefer `test -f ~/.config/galaaz/profiles/arrow` over invoking R.

### Tests (add-ons)

Run on WSL/checkout first, then TryOmarchy (after D-T9). **Ledger (P-T8 / P-T9) is required** for TryOmarchy dogfood and pitch readiness (S7). Do not block Phase F (upstream **core** PR) on Bio/TeX; Ledger stays overlay-only and is not part of the upstream diff.

| Test | Procedure | Pass |
|------|-----------|------|
| P-T1 | Without core, `galaaz add arrow` | non-zero |
| P-T2 | `galaaz add knit` twice | second is no-op, exit 0 |
| P-T3 | Knit `oh_my` HTML to `/tmp/out` | HTML exists |
| P-T4 | `galaaz add arrow` + Ruby snippet that needs R `arrow` (or skip with clear message if build failed) | `requireNamespace('arrow')` true |
| P-T5 | `galaaz add tex` + `which pdflatex` or TinyTeX bin | found |
| P-T6 | `galaaz add bio` (slow; once per machine) | `requireNamespace('DESeq2')` |
| P-T7 | `galaaz add examples` | `~/galaaz-examples` has expected dirs |
| P-T8 | Menu **Ledger** or `galaaz add ledger` / `omarchy-galaaz-add ledger` | `~/r_on_rails_ledger` Gemfile has no `path: "../galaaz"`; `db:prepare` + fast seed OK; profile `~/.config/galaaz/profiles/ledger` |
| P-T9 | `cd ~/r_on_rails_ledger && bin/dev` | http://localhost:3000 loads; Local R stress test completes (Arrow path) |
| P-T10 | Remove core Galaaz; `~/r_on_rails_ledger` still on disk; R `arrow` still installed | documented leftover |

---

## Phase B — Stranger-machine tests we already have

**Why:** Prove the **gem** path, not the git tree. Omarchy users will not clone us.

| Test | Command | Pass |
|------|---------|------|
| B-T1 | `./docker/cold-install-cruby/run.sh` | `cold-install smoke: OK` |
| B-T2 | `./docker/cold-install-cruby/run.sh published-specs` | rspec from **installed gem** (no repo mount) |
| B-T3 | Same as B-T1 but `GALAAZ_COLD_INSTALL_SOURCE=rubygems` (or the published-gem path documented in `run.sh`) | works against **released** gem, not only a local `.gem` |

B-T3 is **mandatory before any upstream PR**. DHH will `gem install galaaz` from RubyGems, not from a branch `.gem`.

After A.1 ships, extend `install-and-smoke.sh` to call `galaaz setup` and `galaaz blogs init` instead of raw `make -C …`.

| Test | Command | Pass |
|------|---------|------|
| B-T4 | Cold CRuby image: `galaaz setup && galaaz blogs init /tmp/blogs && test -f /tmp/blogs/oh_my/oh_my.Rmd` | exit 0 |

---

## Phase C — Installer scripts in *this* repo (Arch-shaped, Omarchy-compatible)

**Why:** Write and review the script here first. The Omarchy PR only **copies the case arm**.

Add something like:

- `script/omarchy/install-galaaz.sh`
- `script/omarchy/remove-galaaz.sh`

They must be written as if they will be pasted into `omarchy-install-dev-env`:

- `#!/bin/bash`, `set -euo pipefail` if we keep them standalone; the in-tree Omarchy case may omit `set` to match neighbors
- `omarchy-pkg-add` for Arch packages when the command exists; otherwise document the pacman equivalents for local testing: `r`, `r-devel` or Arch’s `r` + `gcc`/`make`, `libyaml` if Ruby compiles
- `mise use --global ruby@latest` only if `ruby` is missing; **do not** `mise uninstall ruby` on remove
- `mise x ruby -- gem install galaaz --no-document`
- `mise x ruby -- galaaz setup`
- `mise x ruby -- galaaz blogs init "$HOME/galaaz-blogs"`
- Echo: `You can now run: galaaz doctor` (or `gstudio` if that is the omakase command)

**Remove** must:

- `gem uninstall galaaz -x -a` (under mise ruby)
- Remove `~/galaaz-blogs` only if it was created by us (marker file `.galaaz-omarchy-blogs` or similar) — **never** delete an unrelated directory
- **Not** uninstall `r` if the user had R before (detect via marker or leave R installed; document the choice: **leave R** is safer for a Rails/data user)
- **Not** `mise uninstall ruby`

### C.1 Local tests (WSL Ubuntu is *not* Arch)

On current WSL, we can only test the **Ruby/gem/R** half, not `omarchy-pkg-add`.

| Test | Check | Pass |
|------|--------|------|
| C-T1 | Dry-read scripts vs AGENTS.md (shebang, helpers, no `exit` surprises) | review |
| C-T2 | On WSL: run the gem/R portion of install-galaaz (skip pacman) against mise or system ruby | A-T4/A-T5 pass |
| C-T3 | Remove script leaves `ruby` and `R` on PATH | `command -v ruby`; `command -v R` |

**Arch proof** waits for TryOmarchy (Phase D). Optional extra: an Arch Docker with mise + R if we want C-T4 before Windows.

| Test | Command | Pass |
|------|---------|------|
| C-T4 (optional) | Arch container: install-galaaz.sh | S2+S3 without Omarchy menu |

---

## Phase D — TryOmarchy + `galaaz omarchy` overlay

**Why:** Real Omarchy menu, real pacman, disposable VM. Overlay first; do not patch `/usr/share/omarchy`. Prefer **`galaaz omarchy`** over hand-copying scripts (avoids partial/wrong `~/.local/bin` copies).

### D.1 Host prerequisites (Windows 11)

| Step | Action |
|------|--------|
| D.1.1 | Windows 11 with virtualization enabled (same platform WSL2 uses) |
| D.1.2 | Download **TryOmarchy.exe** from [tryomarchy.com](https://tryomarchy.com/) (~8 MB). Unofficial; not affiliated with Basecamp/DHH |
| D.1.3 | First run: allow Hypervisor Platform if Windows prompts; reboot if asked; let it pull GPU runtime + Omarchy image (~1.5 GB) |
| D.1.4 | Confirm the guest boots to the Omarchy desktop inside a window |

**Reset (use this often):** uninstall by deleting `%LOCALAPPDATA%\TryOmarchy` (and the Start-menu shortcut if any), then run `TryOmarchy.exe` again. That is the clean-room for S5.

If first-run artifacts live elsewhere, note the actual paths in the run log when discovered.

### D.2 Inside the guest — baseline Omarchy

| Step | Action | Pass |
|------|--------|------|
| D.2.1 | Super+Space → **Install → Development → Ruby on Rails** | `ruby -v`, `rails -v` |
| D.2.2 | Confirm `mise` on PATH | `mise --version` |
| D.2.3 | Optional: `mise settings` shows `ruby.compile` false (Omarchy default) | binaries, not a 20-minute ruby-build |

### D.3 Install overlay (canonical — no manual `cp`)

TryOmarchy is a VM; the Galaaz git repo on WSL is **not** needed in the guest.

**Preferred path (gem 2.1.7+):**

```bash
# mise Ruby from D.2
gem install galaaz          # or: gem install galaaz -v 2.1.7
galaaz omarchy              # A: overlay files bundled in the gem
galaaz omarchy status       # helpers + menu jsonc present
```

That writes atomically:

| Destination | Source |
|-------------|--------|
| `~/.local/bin/omarchy-install-galaaz` | `script/omarchy/install-galaaz.sh` |
| `~/.local/bin/omarchy-remove-galaaz` | `remove-galaaz.sh` |
| `~/.local/bin/omarchy-galaaz-add` | `galaaz-add.sh` |
| `~/.local/bin/omarchy-galaaz-guide` | `galaaz-guide.sh` |
| `~/.local/bin/omarchy-galaaz-gknit` | `galaaz-gknit.sh` |
| `~/.local/bin/omarchy-galaaz-debug` | `debug-galaaz.sh` |
| `~/.config/omarchy/extensions/omarchy-menu.jsonc` | `omarchy-menu.jsonc` |

**Refresh overlay without a new gem** (e.g. menu/jsonc fix already on GitHub):

```bash
galaaz omarchy install --from-git
# or pin a branch/tag/commit:
galaaz omarchy install --from-git --ref galaaz2_0
# GALAAZ_OMARCHY_REF=… also works
```

`--from-git` needs network and a pushed ref (raw.githubusercontent.com). Default ref is `galaaz2_0`.

**Then install core** (menu or CLI):

```bash
omarchy-install-galaaz
# or: Super+Space → Install → Development → Galaaz → Galaaz (core)
```

Ensure `~/.local/bin` is on PATH (Omarchy normally has it). `galaaz omarchy status` should show no `MISSING` rows before relying on the menu.

**Legacy (avoid):** shared folder / paste / `cp` individual scripts — easy to install the wrong file as `omarchy-galaaz-add` (we hit that). Use only if `galaaz omarchy` is unavailable.

### D.4 Menu overlay (what `galaaz omarchy` installs)

Canonical file: **`~/.config/omarchy/extensions/omarchy-menu.jsonc`** (from the gem’s `script/omarchy/omarchy-menu.jsonc`). Do **not** hand-edit `/usr/share/omarchy`.

Rules from Omarchy `docs/menu.md`:

- JSON plus **whole-line** `//` comments only (inline `//` breaks parse)
- Broken file → **all user rows silently dropped**; shipped menu still works
- Dotted ids place the row; new ids **append** under the parent
- Overlay is watched; no shell restart required (`omarchy menu refresh` if a row does not appear)

**Canonical content** (reference — prefer installing via `galaaz omarchy` rather than pasting). Adjust `action` if launch helper names differ on the installed Omarchy version — Quattro uses `omarchy-launch-tui` / terminal presenters; Docs/GitHub use `omarchy-launch-webapp`:

```jsonc
{
  "install.development.galaaz": {
    "icon": "󰫏",
    "label": "Galaaz",
    "description": "R on Rails"
  },
  "install.development.galaaz.core": {
    "icon": "󰫏",
    "label": "Galaaz (core)",
    "description": "Ruby + R + gem + blogs",
    "action": "omarchy-launch-tui omarchy-install-galaaz",
    "disabled": "omarchy-cmd-present galaaz"
  },
  "install.development.galaaz.knit": {
    "icon": "󰫏",
    "label": "Knit (HTML blogs)",
    "action": "omarchy-launch-tui 'galaaz add knit'",
    "when": "omarchy-cmd-present galaaz",
    "disabled": "test -f ~/.config/galaaz/profiles/knit"
  },
  "install.development.galaaz.arrow": {
    "icon": "󰫏",
    "label": "Arrow",
    "action": "omarchy-launch-tui 'galaaz add arrow'",
    "when": "omarchy-cmd-present galaaz",
    "disabled": "test -f ~/.config/galaaz/profiles/arrow"
  },
  "install.development.galaaz.tex": {
    "icon": "󰫏",
    "label": "TeX (PDF blogs)",
    "action": "omarchy-launch-tui 'galaaz add tex'",
    "when": "omarchy-cmd-present galaaz",
    "disabled": "test -f ~/.config/galaaz/profiles/tex"
  },
  "install.development.galaaz.bio": {
    "icon": "󰫏",
    "label": "Bioconductor (DESeq2)",
    "action": "omarchy-launch-tui 'galaaz add bio'",
    "when": "omarchy-cmd-present galaaz",
    "disabled": "test -f ~/.config/galaaz/profiles/bio"
  },
  "install.development.galaaz.examples": {
    "icon": "󰫏",
    "label": "Examples",
    "action": "omarchy-launch-tui 'galaaz add examples'",
    "when": "omarchy-cmd-present galaaz",
    "disabled": "test -f ~/.config/galaaz/profiles/examples"
  },
  "install.development.galaaz.ledger": {
    "icon": "󰫏",
    "label": "Ledger (R-on-Rails demo)",
    "description": "Clone app, seed, bin/dev",
    "action": "omarchy-launch-tui 'galaaz add ledger'",
    "when": "omarchy-cmd-present galaaz",
    "disabled": "test -f ~/.config/galaaz/profiles/ledger"
  },
  "remove.development.galaaz": {
    "icon": "󰫏",
    "label": "Galaaz",
    "description": "Core gem (add-on R packages stay)",
    "action": "omarchy-launch-tui omarchy-remove-galaaz",
    "when": "omarchy-cmd-present galaaz"
  }
}
```

If `omarchy-cmd-present` is not on PATH in guard evaluation, use `command -v galaaz >/dev/null` (slightly weaker; prefer the helper when it exists).

**Do not** edit `/usr/share/omarchy` or `$OMARCHY_PATH/default/omarchy/omarchy-menu.jsonc`. Updates overwrite those.

### D.5 Exit tests (Phase D) — first TryOmarchy install

| Test | Procedure | Pass |
|------|-----------|------|
| D-T0 | `gem install galaaz` + `galaaz omarchy` + `galaaz omarchy status` | no `MISSING`; menu jsonc present |
| D-T1 | Super+Space → search **Galaaz** | Install row visible under Development |
| D-T2 | Select Install → Development → Galaaz → **Galaaz (core)** | Terminal runs `omarchy-install-galaaz`; no git clone of Galaaz |
| D-T3 | `galaaz doctor` in a new terminal | setup OK |
| D-T4 | Repeat `docker/cold-install-cruby/smoke.rb` logic in guest: `ruby -e "require 'galaaz'; abort unless R.c(1,2,3).to_s.include?('1')"` | exit 0 |
| D-T5 | `ls ~/galaaz-blogs/*/ *.Rmd` | six blogs’ `.Rmd` files |
| D-T6 | Re-open Install → Development → Galaaz → core | row **hidden** (`when:` failed — same as Rails) |
| D-T7 | Remove → Development → Galaaz | `galaaz` gone; `ruby` and `rails` still work |
| D-T8 | Remove row **hidden** after uninstall (`when:` failed) | no Remove Galaaz |
| D-T9 | Re-install via menu (re-run `galaaz omarchy` if helpers were removed) | D-T3–D-T6 pass again |

### D.6 Add-on, Ledger, and knit tests on TryOmarchy

Core D-T0–D-T9 still apply; **Galaaz** is a submenu — D-T1/D-T2 mean **Galaaz → Galaaz (core)**. D-T6 means the **core** row is disabled. Add-on menu actions use **`omarchy-galaaz-add …`** (not a bare quoted `galaaz add`).

**Required on TryOmarchy:**

| Test | Procedure | Pass |
|------|-----------|------|
| D-T10 | **Galaaz → Ledger** (or `omarchy-galaaz-add ledger`) | P-T8: clone + RubyGems Gemfile + seed; ledger profile marked |
| D-T11 | `cd ~/r_on_rails_ledger && bin/dev` | P-T9 / S7: app loads; Local R stress test (Arrow) completes |

Optional on the same guest: P-T2–P-T4 (knit/arrow). Skip P-T5/P-T6 (TeX/Bio) on the nested VM if they exceed E-T2 time budget; run those on WSL. Knit HTML alone is P-T3. PDF blogs need `galaaz add tex` (sty + TinyTeX; `~/sty/galaaz.sty` from blogs init / add tex).

---

## Phase E — Wipe TryOmarchy and repeat (clean-room)

This is the point of using an **application** VM.

| Step | Action |
|------|--------|
| E.1 | Note any extra paths besides `%LOCALAPPDATA%\TryOmarchy` (shortcuts, hypervisor leftover) |
| E.2 | Quit TryOmarchy |
| E.3 | Delete `%LOCALAPPDATA%\TryOmarchy` |
| E.4 | Start `TryOmarchy.exe`; wait for image pull if needed |
| E.5 | Repeat D.2–D.5 **from scratch** (Rails → `gem install galaaz` → `galaaz omarchy` → Galaaz **core**) |
| E.6 | Repeat **D-T10 / D-T11** (Ledger install + `bin/dev` + stress test) on the new guest |

| Test | Pass |
|------|------|
| E-T1 | S1–S4 on a **new** guest with no leftover `~/galaaz-blogs` from the previous VM disk |
| E-T2 | Time the **core** install (wall clock). Record it. If > ~10–15 minutes excluding Rails, slim CRAN/compile before any PR |
| E-T3 | S7 on the new guest: Ledger add-on + app + Local R stress test (same as D-T10/D-T11) |

---

## Phase F — Upstream PR (only after E-T1; Ledger is not in the PR)

Ledger dogfood (E-T3) should pass before you call Omarchy integration “pitch ready,” but the upstream Omarchy PR remains **core-only** (E-T1 is the merge gate for F).

### F.1 What to contribute

Fork [basecamp/omarchy](https://github.com/basecamp/omarchy), branch from the branch they merge to (`master` for Scala).

| File | Change |
|------|--------|
| `bin/omarchy-install-dev-env` | `galaaz)` case; update `omarchy:args=` |
| `bin/omarchy-remove-dev-env` | `galaaz)` case; update args |
| `default/omarchy/omarchy-menu.jsonc` | same two rows as D.4 (ids `install.development.galaaz` / `remove.development.galaaz`) |

Keep the case **short**: pkg-add R toolchain, `gem install`, `galaaz setup`, `galaaz blogs init`, one “You can now run” line.

**Do not** put `galaaz add arrow|bio|tex|ledger` in this PR. Those stay overlay + Galaaz CLI (`galaaz omarchy` + `galaaz add` / `omarchy-galaaz-add`).

### F.2 PR hygiene

- Gem version on RubyGems **already released** (B-T3)
- PR description: tested on TryOmarchy (version/date); one-line user payoff; no Galaaz source in the diff
- Do not reformat unrelated menu entries
- Docs: if they still want manual edits via a **Documentation** issue rather than a markdown novel, file that separately with the exact sentence for [Development Tools](https://omarchy.org/manual/development-tools/)
- Optional: Discussion first (“Install → Development → Galaaz (R on Rails)?”) to test taste before code

### F.3 Tests Omarchy will run

We cannot run their CI from this repo. Before opening the PR:

| Test | Notes |
|------|--------|
| F-T1 | Clone omarchy, apply patch, run their `test/shell.d/menu-test.sh` / `menu-guards-test.sh` if present |
| F-T2 | Mentally check Install uses `disabled:`, Remove uses `when:` |
| F-T3 | Command metadata comments valid (`omarchy:summary`, `omarchy:args`) |

### F.4 If they reject

Keep **`galaaz omarchy`** as the supported Omarchy path (gem-bundled overlay; optional `--from-git`). Document in README / `script/omarchy/README.md`:

```bash
gem install galaaz && galaaz setup && galaaz omarchy
```

That is a complete product without being in the Omarchy catalog. Upstream PR remains optional.

---

## File checklist

| Path | Role | Status |
|------|------|--------|
| Galaaz CLI: `setup` / `blogs init` / `doctor` / `add` / **`omarchy`** | Phase A + overlay install | landed (gem **2.1.7+**) |
| `script/omarchy/*` shipped in gem | Phase C + D overlay sources | landed |
| `script/omarchy/install-galaaz.sh` | Phase C core menu action | landed |
| `script/omarchy/remove-galaaz.sh` | Phase C remove | landed |
| `script/omarchy/omarchy-menu.jsonc` | overlay submenu | landed |
| Ledger: Gemfile RubyGems `galaaz` (optional `GALAAZ_GEM_PATH`) | `galaaz add ledger` | landed on ledger `main` |
| `docker/cold-install-cruby/install-and-smoke.sh` | call `galaaz setup` | landed |
| README / `script/omarchy/README.md` Omarchy section | dogfood docs | landed |

---

## Risks

| Risk | Mitigation |
|------|------------|
| Nested VM too slow to compile gatekeeper / R packages | Slim first install; prebuilt Ruby via mise; record E-T2 |
| TryOmarchy image lags Omarchy Quattro menu helpers | Inspect how Rails install `action` is declared on that image; copy that launcher |
| `galaaz` executable not on PATH under mise shims | Use `mise x ruby -- galaaz` in actions and `disabled:` that matches (`mise which galaaz` or shim path) |
| Guard `omarchy-cmd-present galaaz` false negative | Doctor must install a real `galaaz` bin on PATH |
| Niche-framework rejection by DHH | Overlay forever via `galaaz omarchy`; PR is optional |
| `galaaz add ledger` still has `path: "../galaaz"` | Ledger `main` uses RubyGems galaaz (optional `GALAAZ_GEM_PATH`) |
| R `arrow` compile on Arch/TryOmarchy | `galaaz add arrow` sets LIBARROW_BINARY + LIBARROW_BUILD=false (Apache prebuilt). Do not use pacman `arrow` for CRAN R arrow (version skew). Fail the add-on, not core |
| Hand-copy wrong script into `omarchy-galaaz-add` | Prefer `galaaz omarchy` (atomic install of all helpers) |
| Arch `pandoc` / Haskell mega-deps on knit | `omarchy-galaaz-add` uses pandoc-bin or GitHub static binary |

---

## Run log (fill in as you go)

| Date | Phase / test IDs | Host | Result | Notes |
|------|------------------|------|--------|-------|
| 2026-09-04 | A-T1 setup | WSL checkout (JRuby mise default) | pass | `bin/galaaz setup`; gatekeeper already built |
| 2026-09-04 | A-T2 blogs init | WSL | pass | `/tmp/galaaz-blogs-test` has six `.Rmd` blogs |
| 2026-09-04 | A-T3 second init | WSL | pass | exit 1 without `--force` |
| 2026-09-04 | A-T4 doctor | WSL | pass | setup OK; Rcpp + gatekeeper |
| 2026-09-04 | A-T5 smoke | WSL | pass | `bundle exec ruby -Ilib` → `R.c(1,2,3)` |
| 2026-09-04 | A-T6 add knit | WSL | pass | marker `~/.config/galaaz/profiles/knit`; second add no-op; optional kableExtra compiled from CRAN |
| 2026-09-04 | B-T1 docker smoke | WSL | blocked | Docker daemon not running (`Cannot connect to docker.sock`) |
| 2026-09-04 | B-T4 local gem | WSL CRuby 3.3.12 + temp GEM_HOME | pass | `gem build` → install → `galaaz setup` → `blogs init` → six `.Rmd`; smoke `R.c` OK |
| 2026-09-04 | C-T1 scripts | WSL | pass | `script/omarchy/{install,remove}-galaaz.sh` + `omarchy-menu.jsonc`; `bash -n` OK |

---

## Decision log

| Date | Decision |
|------|----------|
| 2026-09-03 | Plan created. Overlay + TryOmarchy before any basecamp/omarchy PR. CRuby/mise only for Omarchy. Blogs = copy sources from gem; knit is optional. |
| 2026-09-03 | Add-on profiles (`galaaz add`) for Arrow, knit, TeX, Bio, examples, ledger. Upstream PR remains core-only. Ledger on Omarchy uses RubyGems Galaaz, not `path: "../galaaz"`. |
| 2026-09-04 | Phase A CLI landed: `bin/galaaz` → `lib/galaaz/cli.rb` (`setup`, `blogs init`, `doctor`, `add`). Legacy rake still forwarded. Package lists: `r_requires/knit.txt` + `knit-extras.txt`, `arrow.txt`. |
| 2026-09-04 | Phase B/C: cold-install uses `galaaz setup` + `blogs init`; `script/omarchy/` install/remove/menu overlay. Docker B-T1 blocked on this host; local gem B-T4 passed. |
| 2026-09-07 | Ledger dogfood on TryOmarchy in progress (stress test / MC paths); Gemfile RubyGems path fixed |
| 2026-09-08 | **`galaaz omarchy`** (gem 2.1.7): install overlay from gem; optional `--from-git`. Canonical TryOmarchy path — no manual script copy. Sty + TinyTeX PATH for PDF via `blogs init` / `add tex` (2.1.6+). |
