#!/bin/bash
set -e
QMLLINT=$(command -v qmllint 2>/dev/null || true)
[ -z "$QMLLINT" ] && [ -x /usr/lib/qt6/bin/qmllint ] && QMLLINT=/usr/lib/qt6/bin/qmllint
if [ -n "$QMLLINT" ]; then
    echo "Running qmllint"
    find package -name '*.qml' -print0 | while IFS= read -r -d '' file; do
        echo "Linting $file"
        "$QMLLINT" "$file" || true
    done
else
    echo "qmllint not available"
fi
if command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Validating package with kpackagetool6"
    kpackagetool6 --type Plasma/Applet -g package
elif command -v plasmapkg2 >/dev/null 2>&1; then
    echo "Validating package with plasmapkg2"
    plasmapkg2 -t plasmoid -g package
else
    echo "No package validation tool found"
fi
