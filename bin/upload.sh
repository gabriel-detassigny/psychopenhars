#!/usr/bin/env bash
# Upload the committed repo to the server WITHOUT touching anything there:
# it extracts into a new ~/psychopenhars-migration-<commit> folder and aborts
# if that folder already exists. Nothing is ever deleted.
#
# Usage: bin/upload.sh <ssh-target>   e.g. bin/upload.sh user@ssh.clusterXXX.hosting.ovh.net
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

TARGET="${1:?usage: bin/upload.sh <ssh-target>}"
[[ -z "$(git status --porcelain)" ]] || { echo "Commit your changes first (git archive uploads HEAD only)." >&2; exit 1; }
DIR="psychopenhars-migration-$(git rev-parse --short HEAD)"

git archive HEAD | ssh "$TARGET" "set -e
	if [ -e \"\$HOME/$DIR\" ]; then echo \"\$HOME/$DIR already exists, not touching it.\" >&2; exit 1; fi
	mkdir \"\$HOME/$DIR\"
	tar -x -C \"\$HOME/$DIR\"
	chmod 700 \"\$HOME/$DIR\"
	printf '%s\\n' '<IfModule mod_authz_core.c>' 'Require all denied' '</IfModule>' '<IfModule !mod_authz_core.c>' 'Deny from all' '</IfModule>' > \"\$HOME/$DIR/.htaccess\"
	echo \"Uploaded to \$HOME/$DIR\""
