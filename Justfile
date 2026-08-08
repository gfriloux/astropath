default:
    @just --list

# Full quality gate: format + lint + test. The single source of truth for the gates.
ci: fmt-check lint test

# Formats the QML in place (qmlformat).
fmt:
    @find src -name '*.qml' -print0 2>/dev/null | xargs -0 -r qmlformat -i

# Checks formatting without modifying: fails if a file is not formatted.
fmt-check:
    #!/usr/bin/env bash
    set -euo pipefail
    fail=0
    while IFS= read -r -d '' f; do
        if ! diff -q "$f" <(qmlformat "$f") >/dev/null; then
            echo "not formatted: $f"; fail=1
        fi
    done < <(find src -name '*.qml' -print0 2>/dev/null)
    exit $fail

# Static QML lint (qmllint). No warning tolerated.
lint:
    @find src -name '*.qml' -print0 2>/dev/null | xargs -0 -r qmllint

# Golden tests: qmltestrunner runs the JS transforms on fixtures → compares to the goldens.
test:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! find tests -name 'tst_*.qml' 2>/dev/null | grep -q .; then
        echo "no test (tests/tst_*.qml missing)"; exit 0
    fi
    # QtTest (TestCase) imports QtQuick.Window: we point explicitly at qtdeclarative's qml
    # folder (otherwise, in CI without an ambient QML2_IMPORT_PATH, the module is not found).
    qmldir="$(dirname "$(dirname "$(command -v qmltestrunner)")")/lib/qt-6/qml"
    export QML2_IMPORT_PATH="$qmldir${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
    QT_QPA_PLATFORM=offscreen QML_XHR_ALLOW_FILE_READ=1 qmltestrunner -input tests

# Links the plugin into DMS's plugins folder for testing (then enable it in DMS).
run:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"
    mkdir -p "$dir"
    ln -sfn "$PWD" "$dir/Astropath"
    echo "Plugin linked → $dir/Astropath"
    echo "Enable 'Astropath' in DMS (Settings → Plugins). After each change: just reload."

# Starts an *isolated* DMS instance (dedicated config/cache) loading the worktree as the
# « Astropath (dev) » plugin. Tests the in-progress version without touching the daily DMS.
dev-bar:
    @scripts/astropath-dev "{{justfile_directory()}}"

# Reloads DMS: purges the compiled QML bytecode (otherwise the old rendering sticks) then
# restarts the service. Toggling the plugin alone is not enough.
reload:
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/qmlcache"
    systemctl --user restart dms.service

# Regenerates CHANGELOG.md from the Conventional Commits (git-cliff).
changelog:
    git-cliff -o CHANGELOG.md

# Regenerates the goldens from the fixtures (current transform). Review the diff after.
bless:
    QML_XHR_ALLOW_FILE_READ=1 quickshell -p bless.qml
