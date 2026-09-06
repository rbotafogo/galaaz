# Galaaz blogs (gknit)

These are R Markdown (`.Rmd`) documents that use **gknit** to run Ruby/Galaaz chunks and render HTML (or other formats).

**Published renders** (HTML/PDF) are on GitHub Pages:
https://rbotafogo.github.io/galaaz/

The gem ships blog/manual **sources** (and examples/specs); it does not pack `.html` / `.pdf` or prebuilt `.so` / `.o` files.

## Generate a single blog

From the **project root**:

```bash
bin/gknit blogs/<blog_dir>/<blog_dir>.Rmd
```

Examples:

```bash
bin/gknit blogs/oh_my/oh_my.Rmd
bin/gknit blogs/gknit/gknit.Rmd
bin/gknit blogs/galaaz_ggplot/galaaz_ggplot.Rmd
bin/gknit blogs/manual/manual.Rmd
bin/gknit blogs/nse_dplyr/nse_dplyr.Rmd
bin/gknit blogs/ruby_plot/ruby_plot.Rmd
```

Output (e.g. `oh_my.html`) is written in the same directory as the `.Rmd` unless you pass `-d` / `--output_dir`.

## Generate blogs via Rake

From the project root:

```bash
rake blog:oh_my
rake blog:gknit
rake blog:galaaz_ggplot
rake blog:manual
rake blog:nse_dplyr
rake blog:ruby_plot
```

Each task runs `bin/gknit` on `blogs/<name>/<name>.Rmd`.

## gknit options

```bash
bin/gknit -h
```

Useful options:

- `-f FILE` / `--filename FILE` – input `.Rmd` (or pass the path as first argument).
- `-o FILE` / `--output_file` – output filename.
- `-d DIR` / `--output_dir` – output directory.
- `--output_format FORMAT` – e.g. `html_document` (default is from the YAML header).

Example with options:

```bash
bin/gknit blogs/oh_my/oh_my.Rmd -d /tmp/out --output_format html_document
```

## Debugging R and monitoring R independently

R runs as a **separate process**. With `--debugR` you can capture what Galaaz sends to R and what R prints, then inspect or replay it on your own.

### Turn on R debugging

```bash
bin/gknit --debugR blogs/oh_my/oh_my.Rmd
```

Or set the env var for any Galaaz command:

```bash
GALAAZ_DEBUG_R=1 bin/run_example examples/sthda_ggplot/all.rb
```

### Log files (written in current directory when `GALAAZ_DEBUG_R=1`)

| File | Content |
|------|--------|
| **logs/galaaz_r_scripts.log** | Every R script sent to the bridge (full tryCatch wrapper), in order. |
| **logs/galaaz_r_stdout.log** | Raw stdout from the R process (everything R printed), in order. |
| **logs/galaaz_r_pid.txt** | R process PID (so you can attach or inspect the process). |
| **logs/galaaz_r_stderr.log** | R stderr (always written, not only with `--debugR`). |

### Monitoring R independently

- **See what R ran:** Open `logs/galaaz_r_scripts.log` and `logs/galaaz_r_stdout.log` in another terminal (e.g. `tail -f logs/galaaz_r_stdout.log`) while the job runs.
- **Replay in a separate R session:** Start R in another terminal. Copy script blocks from `logs/galaaz_r_scripts.log` (or `source('/dev/shm/galaaz_cmd_N.R')` if the temp files still exist) and run them in order. Then inspect `.GlobalEnv`, `ls()`, `traceback()`, etc.
- **Inspect the live R process:** Use the PID from `logs/galaaz_r_pid.txt` with OS tools (e.g. `/proc/<pid>/` on Linux) or attach a debugger if needed.

## Requirements

- **JRuby** or **CRuby** (same as specs/examples; use `bin/galaaz-ruby` / `GALAAZ_RUBY`).
- **R** with packages used by the document (e.g. `rmarkdown`, `knitr`, `ggplot2`).
- Run from the project root so `lib` and `bin` resolve correctly.
