# DESeq2 airway: fair benchmark (R vs galaaz, warm semantics)

This document describes a **production-oriented** comparison: both R and galaaz execute the **same statistical pipeline three times in one long-lived process**. Run 1 pays interpreter warm-up (packages, JIT, caches); **runs 2–3** are the “steady state” we care about for services and notebooks that stay up.

It is **not** a fair comparison to time three separate `Rscript` invocations against three `load`s in one JRuby process: separate processes **never** share R’s in-memory warm state.

## What is being timed

- **R:** `DESeq2` + `airway`, same steps as `examples/bioconductor_deseq2_airway/deseq2_airway_minimal.R`, with **PDF output** (`plotMA`) so graphics behavior matches the galaaz examples (see `deseq2_airway_pipeline_for_bench.R`).
- **galaaz:** `examples/bioconductor_deseq2_airway/deseq2_airway_galaaz_optimized.rb` (or `deseq2_airway_galaaz.rb`) loaded three times via `load` in **one** `bin/galaaz-jruby` process.

## How to reproduce

From the **repository root**, with Bioconductor packages available to R:

```bash
# R — three runs, one process
Rscript examples/bioconductor_deseq2_airway/bench_r_three_same_process.R

# galaaz — three runs, one process (JRuby flags via wrapper)
bin/galaaz-jruby examples/bioconductor_deseq2_airway/bench_galaaz_three_same_process.rb optimized
bin/galaaz-jruby examples/bioconductor_deseq2_airway/bench_galaaz_three_same_process.rb original
```

Optional: pass the repo root explicitly to the R driver:

```bash
Rscript examples/bioconductor_deseq2_airway/bench_r_three_same_process.R /path/to/galaaz
```

Artifacts:

- R PDF: `examples/bioconductor_deseq2_airway/plotMA_bench_R.pdf`
- galaaz PDFs: `plotMA_galaaz.pdf` / `plotMA_galaaz_optimized.pdf` (unchanged from the examples)

## Reported timings (example machine, WSL2)

All numbers are **wall-clock seconds** per full pipeline execution. **Warm** = median of runs **2 and 3** (same definition in both drivers).

| Harness | Run 1 | Run 2 | Run 3 | Warm (runs 2–3) |
|--------|------:|------:|------:|----------------:|
| R (one process, `bench_r_three_same_process.R`) | 24.23 | 13.44 | 14.00 | **13.72** |
| galaaz optimized — **sample A** | 33.34 | 20.88 | 17.58 | 19.23 |
| galaaz optimized — **sample B** | 25.20 | 14.16 | 13.70 | **13.93** |
| galaaz original — **sample** | 26.85 | 14.28 | 13.87 | **14.07** |

Observations from these samples:

1. **R also speeds up** on runs 2–3 in one process (~24 s → ~13–14 s): same pattern as galaaz (JVM/JRuby + R session already hot).
2. With a “good” galaaz run (**sample B**), **galaaz optimized warm (~13.9 s) matches R warm (~13.7 s)** — same ballpark as a single-process R baseline.
3. **Variance is real** (see sample A for galaaz). For reporting, run the harness **several times** or aggregate medians across days; do not trust a single triple.
4. On these samples, **original vs optimized** galaaz warm times are **similar** once the process is hot; the expensive part is still **DESeq2 compute**. Output style (`puts` vs `R.cat`) matters more when the Ruby↔R chatter dominates; here it is a smaller slice.

## Historical context (galaaz “before” vs “after”)

Earlier notes (e.g. [performance.md](./performance.md)) recorded galaaz **much slower** than R for this workload (e.g. warm loop on the order of **~45 s** vs R ~**26–28 s** on a one-shot `Rscript` baseline). With the **same warm semantics** as above (three runs in one process, optimized script using `R.cat`), **R lands near ~14 s warm** and **current galaaz can land in the same ~14 s band** on a representative run — i.e. **parity with single-process R**, not “magic faster than DESeq2,” when the pipeline is compute-heavy and both sides are warm.

**Caution:** Absolute seconds depend on CPU, BLAS, Bioconductor versions, and system load. The **shape** of the result matters: **fair R comparison = one R process, multiple iterations**, not three cold `Rscript` processes.

**Interpretation:** Galaaz does not need to beat R on wall time—the heavy work still runs in **GNU R**. Warm **parity** with a single-process R baseline means the **Ruby + bridge path adds little on top** of that native execution: the integration layer is doing its job efficiently for this workload.

## Scripts added for this benchmark

| File | Role |
|------|------|
| `examples/bioconductor_deseq2_airway/deseq2_airway_pipeline_for_bench.R` | R pipeline aligned with minimal example + PDF plot |
| `examples/bioconductor_deseq2_airway/bench_r_three_same_process.R` | Times three `sys.source` runs in one R process |
| `examples/bioconductor_deseq2_airway/bench_galaaz_three_same_process.rb` | Times three `load`s in one JRuby process (`optimized` or `original`) |
