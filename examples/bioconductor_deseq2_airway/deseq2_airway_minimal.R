library(DESeq2)
library(airway)

# Load canonical airway example data.
data(airway)
airway$dex <- relevel(airway$dex, ref = "untrt")

# Build DESeq2 dataset using cell line as covariate and dex as treatment.
dds <- DESeqDataSet(airway, design = ~ cell + dex)

# Prefilter genes with almost no counts.
keep <- rowSums(counts(dds)) >= 10
dds <- dds[keep, ]

# Fit DE model and extract treatment effect.
dds <- DESeq(dds)
res <- results(dds, contrast = c("dex", "trt", "untrt"))

# Compact sanity outputs for quick verification.
cat("Samples:", ncol(dds), "\n")
cat("Genes after prefilter:", nrow(dds), "\n")
cat("Result rows:", nrow(res), "\n")
cat("Result columns:", paste(colnames(res), collapse = ", "), "\n")
cat("Significant genes (padj < 0.05):", sum(res$padj < 0.05, na.rm = TRUE), "\n")

res_ordered <- res[order(res$padj), ]
print(head(as.data.frame(res_ordered), 10))

# Standard DESeq2 plot call used in the walkthrough.
plotMA(res, ylim = c(-5, 5))
