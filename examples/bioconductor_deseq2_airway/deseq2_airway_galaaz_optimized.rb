require 'galaaz'

R.library('DESeq2')
R.library('airway')
R.data('airway')

airway = ~:airway

# Build DESeq2 dataset with one-sided formula: ~ cell + dex.
dds = R.DESeqDataSet(airway, design: (:all.til :cell + :dex))

# Prefilter genes with almost no counts.
keep = R.rowSums(R.counts(dds)) >= 10
dds = dds[keep, :all]

# Fit DE model and extract treatment effect.
dds = R.DESeq(dds)
res = R.results(dds, contrast: R.c('dex', 'trt', 'untrt'))

# Ruby-style optimization: delegate object rendering to R print/cat.
padj = res.padj
res_ordered = res[R.order(padj), :all]

R.cat('Samples:', R.ncol(dds), '\n')
R.cat('Genes after prefilter:', R.nrow(dds), '\n')
R.cat('Result rows:', R.nrow(res), '\n')
R.cat('Result columns:', R.paste(R.colnames(res), collapse: ', '), '\n')
R.cat('Significant genes (padj < 0.05):', R.sum(padj < 0.05, na__rm: true), '\n')
R.print(R.head(res_ordered, 10))

# Standard DESeq2 plot call written to file.
R.pdf('examples/bioconductor_deseq2_airway/plotMA_galaaz_optimized.pdf')
R.plotMA(res, ylim: R.c(-5, 5))
R.dev__off
