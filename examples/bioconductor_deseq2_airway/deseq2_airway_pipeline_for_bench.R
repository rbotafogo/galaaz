# DESeq2 airway pipeline for timing benchmarks.
# Logic matches deseq2_airway_minimal.R; plot goes to PDF like the galaaz examples
# (avoids default graphics device variance in headless/automated runs).
#
# Not loaded by default from other examples — use only via bench_r_three_same_process.R.

library(DESeq2)
library(airway)

data(airway)
airway$dex <- relevel(airway$dex, ref = "untrt")

dds <- DESeqDataSet(airway, design = ~ cell + dex)

keep <- rowSums(counts(dds)) >= 10
dds <- dds[keep, ]

dds <- DESeq(dds)
res <- results(dds, contrast = c("dex", "trt", "untrt"))

cat("Samples:", ncol(dds), "\n")
cat("Genes after prefilter:", nrow(dds), "\n")
cat("Result rows:", nrow(res), "\n")
cat("Result columns:", paste(colnames(res), collapse = ", "), "\n")
cat("Significant genes (padj < 0.05):", sum(res$padj < 0.05, na.rm = TRUE), "\n")

res_ordered <- res[order(res$padj), ]
print(head(as.data.frame(res_ordered), 10))

root <- Sys.getenv("GALAAZ_BENCH_ROOT", unset = "")
if (!nzchar(root)) {
  stop("Set GALAAZ_BENCH_ROOT to the galaaz repository root before sourcing this file (see bench_r_three_same_process.R).")
}
pdf(file.path(root, "examples/bioconductor_deseq2_airway/plotMA_bench_R.pdf"))
plotMA(res, ylim = c(-5, 5))
invisible(dev.off())
