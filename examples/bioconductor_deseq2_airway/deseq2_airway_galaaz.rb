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

# Compact sanity outputs for quick verification.
puts "Samples: #{R.ncol(dds)}"
puts "Genes after prefilter: #{R.nrow(dds)}"
puts "Result rows: #{R.nrow(res)}"
puts "Result columns: #{R.colnames(res)}"
puts "Significant genes (padj < 0.05): #{R.sum(res.padj < 0.05, na__rm: true)}"

res_ordered = res[R.order(res.padj), :all]
puts R.head(R.as__data__frame(res_ordered), 10)

# Standard DESeq2 plot call written to file.
R.pdf('examples/bioconductor_deseq2_airway/plotMA_galaaz.pdf')
R.plotMA(res, ylim: R.c(-5, 5))
R.dev__off
