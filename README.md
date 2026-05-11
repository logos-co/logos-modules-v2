# logos-modules-v2

Canonical Logos module catalog. Hosts the official curated set of Logos
modules as submodules and publishes them via the
[`logos-modules-release-action`](https://github.com/logos-co/logos-modules-release-action)
reusable workflows.

This repo replaces the legacy `logos-modules` (single-bundle releases)
with one GitHub release per module-version. Clients (`lgpd`, the Logos
`package_downloader` module, the package-manager UI) discover the repo
by fetching `logos-repo.json` from the default branch root.

## Module set

Bootstrapped from `logos-modules@bump`. Thirteen submodules under
`submodules/`:

| Module | Source |
|---|---|
| `logos-accounts-module` | logos-co |
| `logos-accounts-ui` | logos-co |
| `logos-blockchain-module` | logos-blockchain |
| `logos-blockchain-ui` | logos-blockchain |
| `logos-chat-module` | logos-co |
| `logos-chat-ui` | logos-co |
| `logos-delivery-module` | logos-co |
| `logos-execution-zone-module` | logos-blockchain |
| `logos-execution-zone-wallet-ui` | logos-blockchain |
| `logos-storage-module` | logos-co |
| `logos-storage-ui` | logos-co |
| `logos-wallet-module` | logos-co |
| `logos-wallet-ui` | logos-co |

Initial SHAs are pinned by [`scripts/bootstrap-submodules.sh`](scripts/bootstrap-submodules.sh).

## Layout

```
.
├── logos-repo.json                          # repo metadata (name, indexUrl, trusted signers)
├── .gitmodules                              # submodule declarations
├── scripts/
│   └── bootstrap-submodules.sh              # one-shot SHA-pinned `git submodule add`
├── submodules/                              # one git submodule per module
│   ├── logos-chat-module/
│   ├── logos-wallet-module/
│   └── ...
└── .github/workflows/
    ├── _release-module.yml                  # base — single place for signing config
    ├── release-all.yml                      # umbrella: matrix-fans-out to every module
    ├── release-logos-chat-module.yml        # per-module (passes only module_path)
    ├── release-logos-wallet-module.yml
    ├── ...
    └── rebuild-index.yml                    # rolls up the catalog index after each release
```

### Workflow architecture

A two-tier reusable-workflow structure so the signing pipeline lives in
exactly one place:

- **`_release-module.yml`** — local reusable workflow that calls
  `logos-co/logos-modules-release-action@v1` with our chosen
  `signing_mode` and secret wiring. It has only `workflow_call` (no
  `workflow_dispatch`), so it never appears as a runnable item in the
  Actions UI — it's only invoked from other workflows in this repo.
- **`release-<module>.yml`** (13 of them) — manually-triggered
  per-module workflows. Each passes just `module_path: submodules/<repo>`
  to `_release-module.yml` and inherits all secrets.
- **`release-all.yml`** — manually-triggered umbrella. Uses a
  `fail-fast: false` matrix over every submodule name and calls
  `_release-module.yml` for each in parallel. Useful for the initial
  bootstrap and for coordinated cross-module releases.

To switch signing modes (e.g. from inline to a Jenkins HSM):

> Edit `_release-module.yml` ONLY. The 13 per-module callers and the
> umbrella don't need to change.

Comments in `_release-module.yml` show the inline and external
configurations side-by-side.

## Bootstrap

After pushing this skeleton to GitHub for the first time:

```bash
git clone https://github.com/logos-co/logos-modules-v2
cd logos-modules-v2
./scripts/bootstrap-submodules.sh
git add .gitmodules submodules/
git commit -m "Bootstrap submodules from logos-modules@bump"
git push
```

Then add `LOGOS_SIGNING_KEY` (JWK-format Ed25519 secret) to the repo's
Actions secrets and trigger the umbrella **Release all modules**
workflow to publish every initial release in one shot:

```bash
gh workflow run "Release all modules"
```

Individual modules can be cut afterwards via their own
`Release <module>` workflow when their submodule pointer is bumped.

## Adding a new module

1. Add the module as a git submodule under `submodules/`:
   ```bash
   git submodule add https://github.com/logos-co/<repo> submodules/<repo>
   ```
2. Add a `.github/workflows/release-<repo>.yml` calling the
   `logos-modules-release-action` reusable workflow (see the existing
   release files as templates — they only differ in `module_path`).
3. Trigger the new workflow to bootstrap a release.

## Cutting a release

Bump the submodule pointer (and thereby its `metadata.json#version`),
push, then trigger the matching `release-<module>.yml` via
`gh workflow run` or the Actions UI. The action will:

- Build the `.lgx` per variant, merge them, verify, sign with the
  inline `LOGOS_SIGNING_KEY` secret.
- Publish a release tagged `<module>-v<version>`.
- Trigger `rebuild-index`, which regenerates `index.json` on the
  rolling `index` release.

Clients pick up the new version on their next catalog refresh.

## Migration from `logos-modules`

The legacy `logos-co/logos-modules` repo keeps its existing
`list.json`-based bundle releases as a frozen archive — no code path in
the new client reads them. Users on older app versions can continue to
install from there until they upgrade.
