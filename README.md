# astropath

A mail widget for **Quickshell / DankMaterialShell**. An unread badge in the bar, and a
popup to scan threads, search, retag and open a mail. Data comes from **notmuch**
(indexed Maildir); everything is reasoned about by **thread** and by **tag**.

> The warp is calm. The astropath keeps watch.

## Stack

- **View**: QML / Qt Quick via [Quickshell](https://quickshell.outfoxxed.me/), Material 3,
  Catppuccin Mocha theme.
- **Data**: `notmuch` (reading + tag mutation). Syncing is handled by `offlineimap`
  + `imapnotify`. Opening a thread delegates to a configurable external mail client
  (`alot` today); astropath is a **triage** surface, not a full client.

Architecture, invariants and visual system: [`DESIGN.md`](./DESIGN.md).

## Development

The project uses a Nix dev shell (Quickshell, notmuch, qmllint/qmlformat, just):

```bash
nix develop
just            # list targets
just ci         # format + lint + test
just run        # launch the widget for manual testing
```

Pre-commit hooks: `pre-commit install`. `just run` links the plugin into the DMS folder,
`just reload` reloads DMS (toggling the plugin does not re-read the QML).

### Testing the in-progress version in an isolated bar

`just run` shares your daily DMS. To iterate **without** touching the installed instance
(via the home-manager module), `just dev-bar` starts a **second, isolated DMS instance**:

```bash
just dev-bar                       # from the dev shell
# or, without cloning the repo into PATH:
nix run github:gfriloux/astropath#dev-bar -- /path/to/the/worktree
```

It uses a dedicated `XDG_CONFIG_HOME`/`XDG_CACHE_HOME` (`~/.local/state/astropath-dev/`),
so settings, plugin folder and **qmlcache** are separate from the daily DMS (edit →
restart, no cache purge needed). The worktree is mounted as a live symlink under the label
**"Astropath (dev)"** — the plugin id stays `astropath` (it must stay aligned with
`pluginId` in `Settings.qml`), only the display name changes, to tell the two bars apart.
Enable it once in *Settings → Plugins* of that instance; if it overlaps the top bar, move
it once (other screen/edge), which persists in its config.

## Installation

astropath is a **DankMaterialShell plugin**. Via the home-manager module:

```nix
inputs.astropath.url = "github:gfriloux/astropath";

# home-manager config:
imports = [ inputs.astropath.homeModules.default ];
programs.astropath.enable = true;
```

The module installs the plugin into `~/.config/DankMaterialShell/plugins/Astropath/`;
you still have to **enable it in DMS** (Settings → Plugins → Astropath) and configure the
reading client and smart folders in its settings.

## Code structure

- `plugin.json` — DMS plugin manifest (widget type, permissions, icon).
- `src/query/` — notmuch command construction (argv), pure JS.
- `src/model/` — `notmuch` JSON → model transforms (`parseSearch`/`parseCount`/
  `savedSearches`/`parseShow`) + `format.js`, pure JS tested by goldens.
- `src/view/` — QML plugin: bar widget, cockpit (popout), settings. Theme inherited from DMS.
- `tests/` — notmuch fixtures + goldens. `just test` (qmltestrunner), `just bless`
  (regenerates). Synthetic test data.
- `nix/hm-module.nix` — home-manager module (installs the plugin, daily instance).
- `scripts/astropath-dev` — starts an isolated DMS instance on the worktree (`just dev-bar`).

## Contributing

No code without an approved plan. Read [`DESIGN.md`](./DESIGN.md) then
[`PROCEDURE_PLANS.md`](./PROCEDURE_PLANS.md) before any change. Git policy is
**hybrid**: work on a dedicated branch, atomic commits (Conventional Commits),
merge/push/tag reserved for the maintainer.

## Release

- **Changelog**: Conventional Commits → `CHANGELOG.md` via `git-cliff` (`just changelog`).
- **Release**: on a `v*` tag, the GitHub workflow generates the notes (git-cliff) and
  creates the release. No binary artifact (the plugin is source; install via a flake
  pinned to the tag).
- **Dependencies**: Renovate (flake.lock + GitHub Actions, weekly grouped updates).

## License

See [`LICENSE`](./LICENSE).
