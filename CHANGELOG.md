# Changelog

## 2.0.0

Galaaz 2.0 drives **GNU R** from **JRuby** over a process bridge. It is not the older GraalVM / TruffleRuby / FastR stack, and it does not embed Renjin. Developed and tested on **JRuby 10.1.1.0** (Ruby 4.0) with **Java 21**.

### Added

- NewBridge: JRuby talks to standard GNU R (CRAN / Bioconductor, including compiled packages).
- Native gatekeeper under `ext/new_bridge` (Rcpp / C++); compile after install with `make -C ext/new_bridge all`.
- Optional Apache Arrow helpers for large tables on the R side.
- Rendered manuals, blogs, and examples on [GitHub Pages](https://rbotafogo.github.io/galaaz/).
- Ubuntu cold-install proof (`docker/cold-install`) and GitHub Actions CI for the fast suite plus that image.

### Changed

- The gem ships sources, specs, and examples; it does not pack prebuilt `.so` objects or knitted HTML/PDF.
- The supported install is `jruby -S gem install galaaz`, then compile the gatekeeper (see the README). A git clone is for contributors.

### Known limits

- Primary targets are Linux (x86_64) and macOS; on Windows use WSL2. Native Windows is not supported.
- `grun`, `gknit_Rscript`, and the polyglot path in `gknit-draft` are leftover from the Graal era; use `galaaz-jruby` / `gknit`.
- The gatekeeper must be compiled on the install machine (Rcpp + C++ toolchain); it is not a prebuilt binary in the gem.
- Multi-runtime Docker R (Phase 4.5) is a slow integration spec, not part of cold-install CI.
- The gknit installation-timeout spec is skipped pending a dedicated pass; SimpleCov is a development gem and is not installed in the smoke image.
