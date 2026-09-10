# Galaaz examples

Copied here by `galaaz add examples` (default: `~/galaaz-examples`).

These are Ruby scripts that use the **installed `galaaz` gem** and GNU R. From a
git checkout you can also use `bin/run_example` / `bin/galaaz-ruby`; after a gem
install on Omarchy, use plain `ruby` as below.

## Prerequisites

```bash
galaaz doctor          # setup OK, gatekeeper, Rcpp
# plots:      galaaz add knit   (ggplot2 and friends)
# Arrow IPC:  galaaz add arrow  (Stage A/B)
# Bio:        galaaz add bio    (DESeq2 / airway)
```

If you built Arrow GLib under `/usr/local` (Omarchy Stage B):

```bash
source ~/.config/galaaz/arrow-env.sh   # or open a new shell after menu Arrow
```

Graphical examples need a display (Omarchy Wayland session is fine).

## Run a script (gem / Omarchy)

```bash
cd ~/galaaz-examples

# small / misc
ruby misc/subsetting.rb
ruby misc/ggplot.rb

# ISLR chapter demos (installs ISLR/MASS on first run)
ruby islr/ch3_boston.rb

# ggplot gallery (many windows / plots)
ruby sthda_ggplot/one_variable_continuous/geom_density.rb
ruby sthda_ggplot/all.rb

# Bioconductor walkthrough (needs galaaz add bio)
ruby bioconductor_deseq2_airway/deseq2_airway_galaaz.rb

# Arrow shard handoff sketch (needs arrow)
ruby multithread_shards_to_r/shards_to_r.rb
```

Under **mise**:

```bash
mise x ruby -- ruby ~/galaaz-examples/misc/ggplot.rb
```

## Layout

| Directory | What |
|-----------|------|
| `misc/` | Short demos (subsetting, ggplot, moneyball) |
| `islr/` | ISLR book chapter scripts / specs |
| `sthda_ggplot/` | ggplot2 gallery (see `sthda_ggplot/README.md`, `RUN.md`) |
| `bioconductor_deseq2_airway/` | DESeq2 airway pipeline |
| `multithread_shards_to_r/` | Parallel shards → R / Arrow sketch |
| `rmarkdown/`, `latex_templates/` | Knit / LaTeX template samples (`gknit`) |
| `50Plots_MasterList/` | Extra plot scripts |

## From a Galaaz git checkout

```bash
bin/run_example examples/misc/ggplot.rb
bin/galaaz-ruby examples/bioconductor_deseq2_airway/deseq2_airway_galaaz.rb
# JRuby:
GALAAZ_RUBY=jruby bin/run_example examples/sthda_ggplot/all.rb
```

## Troubleshooting

- `cannot load such file -- galaaz` → `gem install galaaz` (or `gem list galaaz`)
- `Typelib file for namespace 'Arrow'` → `source ~/.config/galaaz/arrow-env.sh`
- Missing R packages → script often calls `R.install_and_loads`; or `galaaz add knit` / `bio`
- No plot window → run inside a graphical session, not a bare SSH TTY
