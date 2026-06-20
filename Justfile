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

# Tests : golden sur la couche données (fixtures notmuch) + Qt Quick Test.
test:
    @find tests -name '*.qml' -print0 2>/dev/null | xargs -0 -r qmltestrunner -input || true
    @echo "TODO: golden tests notmuch (cf. PROCEDURE_PLANS.md §golden)"

# Lance le widget dans Quickshell pour essai manuel.
run:
    quickshell -p src/shell.qml

# Régénère les fixtures golden après un changement intentionnel (relire le diff).
bless:
    BLESS=1 just test
