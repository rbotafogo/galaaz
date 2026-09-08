# Omarchy dogfood (overlay + scripts)

Not an official Omarchy package. Use these files on [TryOmarchy](https://tryomarchy.com/) or a real Omarchy install **before** any upstream PR.

**Important:** `gem install galaaz` alone does **not** add an Omarchy menu. The menu comes from `omarchy-menu.jsonc` under `~/.config/omarchy/extensions/`.

## Files

| File | Role |
|------|------|
| `install-galaaz.sh` | Core install; always writes `~/.local/share/galaaz/install-core.log` |
| `galaaz-guide.sh` | Guide / docs / knit-demo helper (`omarchy-galaaz-guide`) |
| `debug-galaaz.sh` | Snapshot doctor/PATH/gem/bridge → `~/.local/share/galaaz/debug.log` |
| `remove-galaaz.sh` | Uninstall gem + marked blogs; leave R |
| `omarchy-menu.jsonc` | Menu overlay submenu under Install → Development |

After core, the menu includes **Guide (what's next)**, **Documentation (website)**, and **GitHub repository**. After Knit, **Knit demo (oh_my)** runs an example blog.

Docs: https://rbotafogo.github.io/galaaz/ · https://github.com/rbotafogo/galaaz

Heavy CRAN installs (`R.install_and_loads`) and long R (`R::Job.eval` / `script`) run in a
child `Rscript` so the bridge stays free — see **Background R jobs (`R::Job`)** in the
README / manual (gem **2.1.5+**).

## TryOmarchy steps

1. Install → Development → Ruby on Rails (mise Ruby).
2. Copy scripts into the guest (once):

```bash
mkdir -p ~/.local/bin ~/.config/omarchy/extensions
cp install-galaaz.sh ~/.local/bin/omarchy-install-galaaz
cp remove-galaaz.sh ~/.local/bin/omarchy-remove-galaaz
cp omarchy-menu.jsonc ~/.config/omarchy/extensions/omarchy-menu.jsonc
chmod +x ~/.local/bin/omarchy-install-galaaz ~/.local/bin/omarchy-remove-galaaz
```

3. Super+Space → search **Galaaz**, or Install → Development → **Galaaz** → **Galaaz (core)**.

That action must finish **gem + setup + blogs + doctor**. It fails if the gatekeeper `.so` is missing — “gem 2.1.1 installed” alone is not success.

After editing `install-galaaz.sh` on the host, re-copy it to `~/.local/bin/omarchy-install-galaaz` before clicking core again (the menu runs that bin).

4. After core finishes, the same submenu shows Knit / Arrow / TeX / Bio / Examples / Ledger.

If you already `gem install`ed but never ran setup, open the menu and click **Galaaz (core)** again (with the updated overlay — core stays enabled until `~/.config/galaaz/profiles/core` exists).

5. **Ledger (required dogfood / pitch):** Install → Development → **Galaaz → Ledger**
   (or `omarchy-galaaz-add ledger` / `galaaz add ledger`). That pulls **arrow** if
   needed using Apache’s **LIBARROW_BINARY** prebuilt libarrow (no manual steps;
   Arch `pacman` arrow is not used for the R package — version skew breaks
   configure), clones `~/r_on_rails_ledger`, rewrites any `path:` gem to RubyGems
   galaaz, then `bundle install` + fast seed.

   Refresh the gem (or reinstall core) so `galaaz add arrow` includes this
   behaviour; also re-copy `galaaz-add.sh` → `~/.local/bin/omarchy-galaaz-add`.

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
