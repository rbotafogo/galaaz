# Changelog

## Unreleased

## 2.1.10.pre.13

### Fixed

- Omarchy Install rows back to **`disabled:`** (dim + ✓), matching Rails / the
  last known-good Galaaz overlay — not `when:` hide. Nested Knit/Arrow/Ledger
  are still under **Install → Development → Galaaz**; typing a letter in the
  menu search lists them as flat hits with a Galaaz breadcrumb (Omarchy search
  UX, not a broken tree).
- Font install: restore the pre.6 fontconfig snippet; always `cp -f`
  `omarchy-with-galaaz.ttf`. After upgrade run `galaaz omarchy install` and
  restart the Omarchy shell so Qt reloads family `omarchy` / U+E90E.

## 2.1.10.pre.12

### Fixed

- Omarchy menu guards: use `$HOME` + `[[ ]]` (stock Omarchy style). Prior
  `test -f ~/.config/...` checks failed in the menu guard batcher, so only
  **Galaaz (core)** appeared and add-ons never showed; brand glyph path also
  refreshed on core/omarchy install (`omarchy-with-galaaz.ttf` + fc-cache).
- Install catalog: add-on rows are visible before core (each hides when its
  own profile exists); `galaaz add` still requires core.

## 2.1.10.pre.11

### Changed

- Omarchy menu: Install rows **hide** after install (`when:` negated profile
  checks, same as Rails) instead of dimming with `disabled:`.
- Omarchy menu: Guide / Documentation / GitHub move to **Learn → Galaaz**;
  Install → Development → Galaaz keeps core, add-ons, and Arrow debug only.
  Remove → Galaaz shows only while core is present.

## 2.1.10.pre.10

### Changed

- Omarchy: split Arrow menu into **Arrow (R only)** (`galaaz add arrow-r`) and
  **Arrow (Ruby)** (`galaaz add arrow-ruby`). Ruby install always ensures R only
  first; no Stage A/B labels in the UI. Legacy `galaaz add arrow` aliases to
  `arrow-ruby`. Ledger/demo pull `arrow-ruby`. Guide, doctor, and Arrow debug
  use the same wording. Examples tree ships `examples/README.md` with run hints.

## 2.1.10.pre.9

### Fixed

- Omarchy Arrow Stage B: slim arrow-glib build (hide flight/dataset/parquet from
  pkg-config) to avoid TUI OOM; traced install log; doctor reports arrow C++ /
  arrow-glib / R arrow / red-arrow; do not mark `profiles/arrow` until Stage B
  succeeds; menu **Arrow debug** helper; persist `GI_TYPELIB_PATH` /
  `LD_LIBRARY_PATH` in `~/.config/galaaz/arrow-env.sh` so `require "arrow"` works
  without manual exports.

## 2.1.10.pre.8

### Fixed

- Omarchy `galaaz-add` arrow: on pacman mirror 404s (stale DB), refresh with
  `pacman -Sy` and retry install before failing.
- Omarchy arrow-glib build: auto-install `glib2-devel` + `cmake` (and other
  build deps) via the add wrapper — no manual `pacman`; default `-j1`, add
  build swap when RAM is low, compile in a systemd user scope with heartbeats
  so OOM kills the build instead of the TUI. Stage B (red-arrow) stays on the
  menu Arrow / ledger / demo path.

## 2.1.10.pre.7

### Added

- Omarchy: Nautilus Scripts under **Scripts → Galaaz** (Gknit HTML / PDF /
  Choose Format) installed by `galaaz omarchy` and core configure.
- Omarchy `galaaz-add` for arrow/ledger/demo: install Arch `arrow` and build
  matching Arrow GLib into `/usr/local` so `red-arrow` can compile.

## 2.1.10.pre.6

### Changed

- Omarchy **Galaaz (core)** no longer runs `gem install` / uninstall. Flow is:
  `gem install galaaz` → `galaaz omarchy install` → menu core (setup + blogs).
- `galaaz --version` / `-v` / `version` prints the installed gem version;
  `galaaz doctor` shows `version:`.
- `galaaz blogs sync` refreshes sty + logo includes without wiping blogs;
  core installer syncs on re-run; `galaaz add knit` refreshes brand assets.

## 2.1.10.pre.5

### Fixed

- Omarchy menu icons: use `"iconFont": "omarchy"` + **U+E90E** via shipped
  `omarchy-with-galaaz.ttf` (Omarchy brand font + Galaaz R/gem). A custom
  family `galaaz` alone rendered as missing-glyph tofu (`//'`) because Qt
  does not load that family for the menu.

## 2.1.10.pre.4

### Fixed

- Omarchy brand icon moved from **U+E900 → U+E920**. E900–E90D belong to
  Omarchy’s own private font (waybar `\ue900`); using E900 made the menu show
  Omarchy’s mark whenever `iconFont: galaaz` failed to win.

## 2.1.10.pre.3

### Fixed

- Omarchy brand icon: hand-drawn R + oversized ruby cutout (no PNG auto-trace);
  build fails if gem hole is too small; preview PNGs at 16/24/48px.
- Omarchy menu: brand icons use `\uE900` + `iconFont: galaaz`; remove separate
  TeX menu row (Knit installs TinyTeX); remove Knit demo (oh_my).

## 2.1.10.pre.2

### Fixed

- **gemspec**: `_logo_before_body.html` and `images/galaaz-lockup-stacked.png`
  were excluded by the `.html`/`.png` filter — pandoc error 99 on Omarchy
  after `gem install`. Blog asset whitelist now ensures these ship with the gem.
- **doctor**: checks sty assets (`galaaz-header.png`, `galaaz-headers-from-p3.tex`)
  and per-blog knit assets (`_logo_before_body.html`, lockup PNG).
- Omarchy menu: install Knit also runs TeX (TinyTeX); removed Knit demo (oh_my)
  entry; font install now runs `fc-cache -r` before refreshing `galaaz.ttf`.

## 2.1.10.pre.1

Prerelease of blog-asset / doctor fixes (superseded by 2.1.10.pre.2).

## 2.1.9

### Added

- `rake release:bump VERSION=x.y.z` (or `bin/release_bump x.y.z`) — rewrite
  `version.rb` and refresh `Gemfile.lock` so CI frozen `bundle install` stays in
  sync; `rake release:check` / CI job `Gemfile.lock matches version.rb` fail early
  with that message instead of Bundler exit 16. `make_gem` / `publish_gem` depend
  on `release:check`.
- Blogs: `galaaz_2_0` and `r_on_rails_ledger` (sources + rendered outputs); listed
  in `galaaz blogs init` / `BLOG_NAMES`.
- Brand kit under `logos/` (incl. transparent masters). PDF headers via
  `sty/galaaz.sty`: small logo left, upright page number + italic uppercase
  section title right; optional `\galaazheaderfrompage` (shared
  `sty/galaaz-headers-from-p3.tex` for title/TOC + splash). Main blogs share
  HTML `before_body` lockup + PDF splash; `galaaz blogs init` / `add tex`
  install sty header PNG and the from-p3 override.
- Omarchy menu brand mark: monochrome icon font `galaaz` (`U+E900`, source
  `logos/icon-font/`) installed to `~/.local/share/fonts/galaaz/` by
  `galaaz omarchy` / core installer — replaces the Ruby-on-Rails Nerd Font gem.

### Fixed

- `galaaz add ledger`: run `rails tailwindcss:build` after seed so Propshaft finds
  `tailwind.css` (builds dir is gitignored).
- Sync `Gemfile.lock` path gem with `version.rb` on every release bump (CI frozen
  install).

## 2.1.8

### Fixed

- `galaaz add ledger`: always `bundle install` under `mise x` (honours app `.ruby-version`),
  ensure the lockfile's bundler is installed, then `bundle update galaaz` and
  `bundle exec` for setup/rails — avoids Omarchy PATH Ruby 4.x mixing with ledger
  Ruby 3.3 and "gems not found" / wrong bundler errors.

## 2.1.7

### Added

- **`galaaz omarchy`**: install the Omarchy menu overlay from files bundled in the gem
  (`script/omarchy/` → `~/.local/bin` + `~/.config/omarchy/extensions/`).
- **`galaaz omarchy install --from-git [--ref REF]`**: same install, but pull overlay
  files from GitHub (default ref `galaaz2_0`, or `GALAAZ_OMARCHY_REF`) without waiting
  for a new gem release.
- **`galaaz omarchy status`**: report whether overlay helpers and menu jsonc are present.

## 2.1.6

### Fixed

- `galaaz blogs init` and `galaaz add tex` install `sty/galaaz.sty` next to the blogs
  tree (e.g. `~/sty/galaaz.sty` for `~/galaaz-blogs`) so PDF `in_header: ../../sty/…`
  works without a manual copy.
- `galaaz add tex` links TinyTeX `pdflatex` (and related tools) into `~/.local/bin` when
  they are not already on PATH (Omarchy / TryOmarchy).

### Changed

- `galaaz doctor` reports `sty` and `pdflatex` status.

## 2.1.5

### Fixed

- `gknit` / `gknit_Rscript`: resolve input with `File.expand_path` so absolute paths
  (e.g. `~/galaaz-blogs/...`) are not prefixed with `Dir.pwd` (broke when run from
  `~/.local/bin`).
- `galaaz add ledger`: do not strip app Ruby version pins; keep engine-agnostic
  RubyGems `gem "galaaz"` rewrites only.

### Changed

- Omarchy `omarchy-galaaz-add`: install pandoc via `pandoc-bin` or the latest GitHub
  linux binary into `~/.local/bin` — not Arch `pandoc` / `pandoc-cli` (Haskell deps).
- Omarchy menu Docs / GitHub rows use `omarchy-launch-webapp` (same as Omarchy Learn).
- `galaaz add arrow` / ledger path: prefer Apache `LIBARROW_BINARY` prebuilt libarrow
  (avoid Arch pacman arrow version skew on Omarchy).

## 2.1.4

### Added

- **`R::Job`**: long CRAN installs (and arbitrary R via `R::Job.eval`) run in a **child
  Rscript** process, not on the NewBridge gatekeeper. Logs and metadata live under
  `~/.local/share/galaaz/jobs/` (override with `GALAAZ_JOBS_DIR`). One install at a
  time (`install.lock`). Bridge R stays free while Ruby awaits the job. Clears stale
  `00LOCK-<pkg>` dirs before install (left behind after kill-on-timeout).
- **Layer C:** `R::Job.eval` / `R::Job.script` for long arbitrary R. Child gets
  `setwd(job.dir)`, `GALAAZ_JOB_DIR`, and `result_path` (default `result.rds`). After
  success, `job.load_rds` does a short sync `readRDS` on the bridge. Block form
  awaits and yields the job (`coef = R::Job.eval(code) { |j| j.load_rds }`).
  Documented in the manual section **Background R jobs (`R::Job`)** (README /
  `blogs/manual/manual.Rmd`).

### Changed

- `R.install_rlibs` / `R.install_and_loads` use `R::Job.install` and **await until
  finished** by default (no bridge 60s install timeout). Optional await limit via
  `install_timeout_sec:` or `GALAAZ_INSTALL_TIMEOUT_SEC` (also `gknit
  --install_timeout_sec`); on timeout the child process group is killed so compile
  work cannot OOM the shell. gknit reports install-job timeouts in the internal
  error summary.

## 2.1.3

### Fixed

- Gatekeeper builds on **R 4.5+/4.6** (Omarchy): replace removed `Rf_findVar` with
  `R_getVarEx` (fallback to `Rf_findVar` on older R).

## 2.1.2

### Fixed

- CRAN installs (`galaaz setup` / `galaaz add`) use a writable user library
  (`R_LIBS_USER`, default `~/.local/lib/R/library`) so Omarchy/Arch no longer fail
  with `lib = "/usr/lib/R/library" is not writable`.
- Gatekeeper `ext/new_bridge` Makefile uses `R CMD config --ldflags` instead of
  hardcoded `-L$(R_HOME)/lib -lR` (breaks when `RHOME` is `/usr/lib64/R`).
- `galaaz setup` marks profile `core` on success.

### Notes

- Omarchy dogfood: `script/omarchy/install-galaaz.sh` installs latest from RubyGems
  (optional pin: `GALAAZ_GEM_VERSION=x.y.z`). Re-copy into `~/.local/bin/omarchy-install-galaaz`
  after updating the script.

## 2.1.1

### Added

- CLI on `bin/galaaz`: `setup`, `blogs init`, `doctor`, `add` (knit / arrow / tex / bio /
  examples / ledger / demo). Legacy unknown args still forward to rake.
- Omarchy dogfood helpers under `script/omarchy/` (install/remove scripts + menu overlay).
- `galaaz doctor` reports both CRuby and JRuby when available (mise-aware).
- Package lists `r_requires/knit.txt`, `knit-extras.txt`, `arrow.txt` for add-on installs.
- Cold-install CRuby path uses `galaaz setup` + `galaaz blogs init`.

### Notes

- Omarchy / stranger install remains `gem install galaaz` then `galaaz setup` (no
  `bundle install` for core use). See `Documentation/PLAN_OMARCHY_INTEGRATION.md`.

## 2.1.0

Galaaz **2.1** keeps the **galaaz2_0** integration line as the main development branch and marks
**CRuby + JRuby** NewBridge support as a released milestone (R-on-Rails positioning).

### Added

- First-class **CRuby** NewBridge path alongside JRuby (engine-aware launchers, cold-install /
  CI coverage for both).
- Docs: treat JRuby and CRuby as equal supported runtimes for the bridge.
- [Documentation/ROADMAP_ARROW_RUBY_R.md](Documentation/ROADMAP_ARROW_RUBY_R.md) — stages A (copy),
  B1/B2 (IPC/mmap file; shipped), C (shared-memory bus; future).
- Stage **B1/B2** APIs: `Galaaz::ArrowIpc`, `R::Arrow.open_ipc`, `R::Arrow.write_ipc` (CRuby
  red-arrow + system Arrow GLib; JRuby Arrow Java + `JAVA_OPTS` nio opens).

### Notes

- Git branch **`galaaz2_0`** remains the integration branch name; the gem version is **2.1.0**.
- Apache Arrow **zero-copy shared RAM** (Stage C) is still future work. Stage A copies into R;
  Stage B uses an IPC file and only the path crosses NewBridge. See the roadmap.

## 2.0.0

Galaaz 2.0 drives **GNU R** from **JRuby** or **CRuby** over a process bridge. It is not the older GraalVM / TruffleRuby / FastR stack, and it does not embed Renjin. Both Rubies are supported for NewBridge (tested on **JRuby 10.1.1.0** with **Java 21**, and **CRuby 3.3.12**).

### Added

- NewBridge: Ruby talks to standard GNU R (CRAN / Bioconductor, including compiled packages).
- Native gatekeeper under `ext/new_bridge` (Rcpp / C++); compile after install with `make -C ext/new_bridge all`.
- Optional Apache Arrow helpers for large tables on the R side.
- Rendered manuals, blogs, and examples on [GitHub Pages](https://rbotafogo.github.io/galaaz/).
- Ubuntu cold-install proof (`docker/cold-install` for JRuby, `docker/cold-install-cruby` for CRuby) and GitHub Actions CI for the fast suite on both engines plus those images.
- Engine-aware launchers (`GALAAZ_RUBY`, `bin/galaaz-ruby`) so the same NewBridge runs under JRuby or CRuby.

### Changed

- The gem ships sources, specs, and examples; it does not pack prebuilt `.so` objects or knitted HTML/PDF.
- The supported install is `gem install galaaz` (under JRuby or CRuby), then compile the gatekeeper (see the README). A git clone is for contributors.

### Known limits

- Primary targets are Linux (x86_64) and macOS; on Windows use WSL2. Native Windows is not supported.
- `grun`, `gknit_Rscript`, and the polyglot path in `gknit-draft` are leftover from the Graal era; use `galaaz-jruby` / `gknit` (or `GALAAZ_RUBY=ruby` for CRuby).
- The gatekeeper must be compiled on the install machine (Rcpp + C++ toolchain); it is not a prebuilt binary in the gem.
- Multi-runtime Docker R (Phase 4.5) is a slow integration spec, not part of cold-install CI.
- The gknit installation-timeout spec covers `R::Job` await timeouts
  (`GALAAZ_INSTALL_TIMEOUT_SEC`); SimpleCov is a development gem and is not installed in
  the smoke image.
