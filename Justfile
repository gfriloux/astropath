default:
    @just --list

# Porte de qualité complète : format + lint + test. Seule source de vérité des gates.
ci: fmt-check lint test

# Formate le QML en place (qmlformat).
fmt:
    @find src -name '*.qml' -print0 2>/dev/null | xargs -0 -r qmlformat -i

# Vérifie le format sans modifier : échoue si un fichier n'est pas formaté.
fmt-check:
    #!/usr/bin/env bash
    set -euo pipefail
    fail=0
    while IFS= read -r -d '' f; do
        if ! diff -q "$f" <(qmlformat "$f") >/dev/null; then
            echo "non formaté : $f"; fail=1
        fi
    done < <(find src -name '*.qml' -print0 2>/dev/null)
    exit $fail

# Lint statique du QML (qmllint). Aucun warning toléré.
lint:
    @find src -name '*.qml' -print0 2>/dev/null | xargs -0 -r qmllint

# Tests golden : qmltestrunner exécute les transforms JS sur fixtures → compare aux goldens.
test:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! find tests -name 'tst_*.qml' 2>/dev/null | grep -q .; then
        echo "aucun test (tests/tst_*.qml absent)"; exit 0
    fi
    QT_QPA_PLATFORM=offscreen QML_XHR_ALLOW_FILE_READ=1 qmltestrunner -input tests

# Lance le widget dans Quickshell pour essai manuel.
run:
    quickshell -p src/shell.qml

# Régénère les goldens depuis les fixtures (transform courant). Relire le diff ensuite.
bless:
    QML_XHR_ALLOW_FILE_READ=1 quickshell -p bless.qml
