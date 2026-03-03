#!/usr/bin/env bash
# scripts/lint.sh — Run SwiftLint and report results
# Can be used as an Xcode pre-action or CI step

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Running SwiftLint..."
cd "$PROJECT_ROOT"

if ! command -v swiftlint &> /dev/null; then
    echo "WARNING: SwiftLint not found. Install with: brew install swiftlint"
    exit 0  # Don't fail CI if swiftlint isn't installed
fi

swiftlint lint --config .swiftlint.yml
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "SwiftLint passed with no violations."
elif [ $EXIT_CODE -eq 1 ]; then
    echo "SwiftLint found warnings. Review above."
    exit 0  # Warnings don't block
else
    echo "SwiftLint found errors. Fix before committing."
    exit 1
fi
