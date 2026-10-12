#!/usr/bin/env bash
# Download the few live-site images the theme patterns and content reference.
# They live in the production media library, so they are not duplicated in git.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

FILES=(
	2023/08/quimper.jpg
	2021/09/alice.png
)
for f in "${FILES[@]}"; do
	dest="local/uploads/$f"
	[[ -s "$dest" ]] && continue
	mkdir -p "$(dirname "$dest")"
	curl -fsSL -o "$dest" "https://psychopenhars.com/wp-content/uploads/$f"
done
