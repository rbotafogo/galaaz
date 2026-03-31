# Running sthda_ggplot examples

Use the same JRuby and JVM options as the specs (required for Apache Arrow).

## Run all sthda_ggplot examples

From the project root:

```bash
jruby -I lib -J--add-opens=java.base/java.nio=org.apache.arrow.memory.core,ALL-UNNAMED examples/sthda_ggplot/all.rb
```

Or with the helper script (if present):

```bash
bin/run_example examples/sthda_ggplot/all.rb
```

## Run a single example

```bash
jruby -I lib -J--add-opens=java.base/java.nio=org.apache.arrow.memory.core,ALL-UNNAMED examples/sthda_ggplot/one_variable_continuous/geom_density.rb
```

Examples that open a display (e.g. `R.awt` / X11) will show a window; some examples use `sleep(2)` between plots.

## Via Rake (default Ruby)

The default task runs all sthda examples:

```bash
rake sthda:all
```

A single example (replace with the file path under `examples/sthda_ggplot/`):

```bash
rake "sthda:one_variable_continuous/geom_density"
```

Note: Rake uses `ruby --polyglot --jvm -Ilib/` (TruffleRuby-style). For JRuby + Shadow Bridge, use the `jruby` command above.
