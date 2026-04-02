# Run the DESeq2 airway pipeline three times in a single R process (fair vs galaaz warm-up).
#
# Usage (from repository root):
#   Rscript examples/bioconductor_deseq2_airway/bench_r_three_same_process.R
#   Rscript examples/bioconductor_deseq2_airway/bench_r_three_same_process.R /path/to/galaaz

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args) >= 1L) {
  normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

Sys.setenv(GALAAZ_BENCH_ROOT = root)
pipeline <- file.path(root, "examples/bioconductor_deseq2_airway/deseq2_airway_pipeline_for_bench.R")
if (!file.exists(pipeline)) {
  stop("Pipeline not found: ", pipeline, " (wrong GALAAZ_BENCH_ROOT?)")
}

cat("=== R: three runs, same process (repository root:", root, ")\n", sep = "")
times <- numeric(3L)
for (i in seq_len(3L)) {
  st <- system.time({
    sys.source(pipeline, envir = new.env(parent = globalenv()), keep.source = FALSE)
  }, gcFirst = FALSE)
  times[[i]] <- unname(st[["elapsed"]])
  cat(sprintf("R run %d/3: %.2f s\n", i, times[[i]]))
}

warm <- times[2:3]
cat("---\n")
cat(sprintf("Warm median (runs 2–3): %.2f s\n", stats::median(warm)))
cat(sprintf("Warm mean (runs 2–3):   %.2f s\n", mean(warm)))
cat(sprintf("All-run median:           %.2f s\n", stats::median(times)))
