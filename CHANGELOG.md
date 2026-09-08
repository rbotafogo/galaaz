# Changelog

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
