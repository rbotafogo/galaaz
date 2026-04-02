# Testing Galaaz

Galaaz specs expect **JRuby** with the JVM flags used by `bin/galaaz_jruby_env.inc.sh` (required for Apache Arrow). Prefer the `bin/` entrypoints over raw `bundle exec rspec` so flags and load path stay consistent.

## Commands

| Command | What it runs |
|--------|----------------|
| `bin/run_rspec` | Default: all top-level files in `specs/` matching `*_spec.rb` or `*.spec.rb`. Loads `specs/spec_helper.rb` (**SimpleCov** → `coverage/`). Does **not** compile the gatekeeper or run `new_bridge_specs/`. |
| `bin/run_rspec path/to/spec.rb` | Same environment; arbitrary spec paths. |
| `bin/run_all_rspec` | Runs the **same top-level `specs/*` files as `bin/run_rspec`** (not nested dirs under `specs/`), plus the **`new_bridge_specs/`** tree, in **one** RSpec process (merged coverage). Runs `make -C ext/new_bridge` first. With **no arguments**, or when the **first** argument is an RSpec option (starts with `-`), those defaults are prepended; otherwise only the paths you pass are run. |
| `bin/run_slow_rspec` | Slower suites under `slow-specs/` (does not load `specs/spec_helper.rb` today). |

## NewBridge-only

To run only gatekeeper/integration specs (after a successful compile):

```bash
make -C ext/new_bridge all
bin/run_rspec new_bridge_specs
```

Using `bin/run_rspec` for `new_bridge_specs` applies the same JRuby flags and **SimpleCov** as the main suite.

## Rake

- `rake compile_gatekeeper` — incremental `make all` in `ext/new_bridge` (task is defined outside the legacy `=begin` block in `Rakefile`).
- `rake specs_all_with_new_bridge` — compile gatekeeper, then JRuby + `specs/spec_helper.rb` + RSpec on `specs/` and `new_bridge_specs/` (mirrors `bin/run_all_rspec`).

## Coverage

With the `simplecov` gem installed, `specs/spec_helper.rb` starts SimpleCov and writes HTML under `coverage/`. Test directories are filtered from coverage metrics; library code under `lib/` is measured.
