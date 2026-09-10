# Omarchy dogfood (overlay + scripts)

Not an official Omarchy package. Community overlay for [TryOmarchy](https://tryomarchy.com/)
or a real Omarchy install. Works **with or without** an upstream Omarchy PR.

## Recommended: `galaaz omarchy` (gem-bundled)

```bash
gem install galaaz            # choose version yourself (stable or .pre.N)
galaaz omarchy install        # menu overlay + helpers (no second gem install)
# optional, newer overlay than the gem:
# galaaz omarchy install --from-git
galaaz omarchy status
```

Then Super+Space → Install → Development → **Galaaz** → **Galaaz (core)**  
(core configures R/gatekeeper/blogs using the **already-installed** gem).

**Important:** `gem install galaaz` alone does **not** add an Omarchy menu until you run
`galaaz omarchy` (or an upstream catalog row exists).

## Files

| File | Role |
|------|------|
| `install-galaaz.sh` | Core configure (R/setup/blogs); uses installed gem; log `~/.local/share/galaaz/install-core.log` |
| `galaaz-guide.sh` | Guide / docs / knit-demo helper (`omarchy-galaaz-guide`) |
| `galaaz-add.sh` | Add-on wrapper (`omarchy-galaaz-add`) — pandoc without Arch Haskell stack |
| `galaaz-gknit.sh` | Safe HTML gknit helper |
| `debug-galaaz.sh` | Snapshot doctor/PATH/gem/bridge |
| `remove-galaaz.sh` | Uninstall gem + marked blogs; leave R |
| `omarchy-menu.jsonc` | Menu overlay submenu under Install → Development |
| `fonts/galaaz.ttf` | Standalone family `galaaz` (debug/previews) |
| `fonts/omarchy-with-galaaz.ttf` | Omarchy brand font + Galaaz at U+E90E (`iconFont: omarchy`) |

Menu rows use the Galaaz icon font (not the Ruby-on-Rails Nerd Font gem). Source SVG
and rebuild script live under `logos/icon-font/`.

After core, the menu includes **Guide (what's next)**, **Documentation (website)**, and **GitHub repository**. After Knit, **Knit demo (oh_my)** runs an example blog.

Docs: https://rbotafogo.github.io/galaaz/ · https://github.com/rbotafogo/galaaz

Heavy CRAN installs (`R.install_and_loads`) and long R (`R::Job.eval` / `script`) run in a
child `Rscript` so the bridge stays free — see **Background R jobs (`R::Job`)** in the
README / manual (gem **2.1.8+**).

## Manual copy (legacy)

Only if you cannot run `galaaz omarchy` yet:

```bash
mkdir -p ~/.local/bin ~/.config/omarchy/extensions
cp install-galaaz.sh ~/.local/bin/omarchy-install-galaaz
cp remove-galaaz.sh ~/.local/bin/omarchy-remove-galaaz
cp galaaz-add.sh ~/.local/bin/omarchy-galaaz-add
cp galaaz-guide.sh ~/.local/bin/omarchy-galaaz-guide
cp galaaz-gknit.sh ~/.local/bin/omarchy-galaaz-gknit
cp debug-galaaz.sh ~/.local/bin/omarchy-galaaz-debug
cp omarchy-menu.jsonc ~/.config/omarchy/extensions/omarchy-menu.jsonc
mkdir -p ~/.local/share/fonts/galaaz
cp fonts/galaaz.ttf ~/.local/share/fonts/galaaz/
fc-cache -f ~/.local/share/fonts/galaaz
chmod +x ~/.local/bin/omarchy-*
# Restart the Omarchy shell so the galaaz font is visible in the menu.```

## TryOmarchy steps

1. Install → Development → Ruby on Rails (mise Ruby).
2. `gem install galaaz && galaaz omarchy install`
3. Super+Space → Install → Development → **Galaaz** → **Galaaz (core)**.

Core configures **setup + blogs + doctor** using the gem you already installed
(it does **not** run `gem install` again). It fails if the gatekeeper `.so` is
missing — “gem installed” alone is not success.

4. After core finishes, the same submenu shows Knit / Arrow (R only) / Arrow (Ruby) /
   TeX / Bio / Examples / Ledger.

5. **Ledger (required dogfood / pitch):** Install → Development → **Galaaz → Ledger**
   (or `omarchy-galaaz-add ledger` / `galaaz add ledger`). That pulls **arrow-ruby**
   if needed (Arrow R only first, then arrow-glib / red-arrow). R’s CRAN arrow uses
   Apache’s **LIBARROW_BINARY** prebuilt libarrow (no manual steps; Arch `pacman`
   arrow is not used for the R package — version skew breaks configure), clones
   `~/r_on_rails_ledger`, rewrites any `path:` gem to RubyGems galaaz, then
   `bundle install` + fast seed.

   **Knit / TeX pandoc:** the add wrapper does **not** install Arch `pandoc` /
   `pandoc-cli` (Haskell mega-deps; often fails on TryOmarchy). It uses
   `pandoc-bin` when available, else the latest official GitHub linux tarball
   into `~/.local/bin` (override with `PANDOC_RELEASE_VER=…`).

   Pass when:

   ```bash
   grep galaaz ~/r_on_rails_ledger/Gemfile   # no path: "../galaaz"
   test -f ~/.config/galaaz/profiles/ledger
   cd ~/r_on_rails_ledger && bin/dev
   ```

   Open http://localhost:3000 → portfolio → **Run stress test** (Local R / Arrow).

6. Before the upstream Omarchy PR: wipe TryOmarchy (`%LOCALAPPDATA%\TryOmarchy`),
   reinstall, and repeat steps 1–5 on a clean guest (plan Phase E, including Ledger).

See `Documentation/PLAN_OMARCHY_INTEGRATION.md` for full phases and tests (D-T10 / D-T11 / E-T3).
