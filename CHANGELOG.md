# Changelog

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
- The gknit installation-timeout spec is skipped pending a dedicated pass; SimpleCov is a development gem and is not installed in the smoke image.
