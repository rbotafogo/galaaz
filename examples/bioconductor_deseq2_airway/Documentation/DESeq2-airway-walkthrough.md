# DESeq2 Airway Walkthrough (Bioconductor + galaaz)

This document defines the first Bioconductor example we will implement with `galaaz`.

## Goal

Run a canonical differential expression analysis from Bioconductor using `DESeq2` and the `airway` dataset, then validate that the workflow executes correctly with `galaaz`.

## Scope

- Focus on workflow execution and interoperability.
- Install Bioconductor dependencies directly in R (outside `galaaz`).
- Keep biological interpretation minimal for this first example.

## Precondition

Before running this example in `galaaz`, install and verify in R:

- `BiocManager`
- `DESeq2`
- `airway`

## Primer (what we are doing)

- RNA-seq count data contains integer read counts per gene and per sample.
- We compare treated vs untreated samples to find genes with significant changes.
- `DESeq2` models count data and returns:
  - `log2FoldChange` (effect size)
  - `pvalue`
  - `padj` (multiple-testing corrected p-value)

## Planned Workflow

1. Load `DESeq2` and `airway`.
2. Load airway data and inspect counts plus sample metadata.
3. Define a design formula for condition effect (with relevant covariate if used in canonical example).
4. Build a `DESeqDataSet` object.
5. Pre-filter low-count genes.
6. Run `DESeq()` to fit the model.
7. Extract `results()` for the treatment comparison.
8. Sort and inspect top hits by adjusted p-value.
9. Produce one standard QC/result plot (for example `plotMA`).

## Validation Checks

- Packages load without runtime errors in the target environment.
- `DESeqDataSet` object is created successfully.
- `DESeq()` completes.
- `results()` returns expected columns and non-empty output.
- At least one standard DESeq2 plot call runs successfully.

## Out of Scope (for now)

- Installing packages via `galaaz`.
- Performance tuning or optimization.
- Deep biological interpretation of gene-level findings.
