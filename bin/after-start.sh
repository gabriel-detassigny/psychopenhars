#!/usr/bin/env bash
# Runs after `wp-env start` (via `npm start`): fetch sample uploads, seed content.
# Not a wp-env lifecycle hook, because a WP_ENV_LIFECYCLE_SCRIPT_AFTER_START
# environment variable (used for Podman permission fixes) would override it.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

bash bin/fetch-uploads.sh
npm run -s seed
