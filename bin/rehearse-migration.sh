#!/usr/bin/env bash
# Rehearse the production migration locally: load a production backup made by
# `scripts/migrate.sh preflight` into wp-env, then run the real migrate.sh
# against it inside the CLI container and check the redirects.
#
# Usage: npm run rehearse -- <backup-dir>
#   <backup-dir> holds db.sql.gz and wp-content.tgz, e.g. fetched with
#   scp -r ovh:psychopenhars-backup-<date> local/prod-backup
#
# Afterwards the local site holds the migrated production copy, including its
# users (log in with your production credentials). `npm run reset` goes back to
# the seeded demo site.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

BACKUP="${1:?usage: npm run rehearse -- <backup-dir>}"
LOCAL_URL="http://psychopenhars.wpenv.net"
[[ -f "$BACKUP/db.sql.gz" ]] || { echo "$BACKUP/db.sql.gz not found" >&2; exit 1; }

CLI="$(docker ps --format '{{.Names}}' --filter 'name=psychopenhars.*cli-1' | head -1)"
[[ -n "$CLI" ]] || { echo "wp-env is not running (npm start)" >&2; exit 1; }
in_cli() { docker exec -i "$CLI" "$@"; }
wp_cli() { in_cli wp --path=/var/www/html "$@"; }

echo "== Production uploads -> local/uploads"
if [[ -f "$BACKUP/wp-content.tgz" ]]; then
	# Extract aside, then copy in: local/uploads may belong to the container's
	# remapped UID (Podman), so tar can't reset its mode or times in place.
	tmp="$(mktemp -d)"
	tar -xzf "$BACKUP/wp-content.tgz" -C "$tmp" wp-content/uploads
	cp -R "$tmp/wp-content/uploads/." local/uploads/
	rm -rf "$tmp"
fi

echo "== Import production database"
# Production may use a different table prefix than wp-env's wp_.
prefix="$(gzip -dc "$BACKUP/db.sql.gz" | sed -n 's/^DROP TABLE IF EXISTS `\(.*\)options`;$/\1/p' | head -1)"
echo "Production table prefix: $prefix"
gzip -dc "$BACKUP/db.sql.gz" |
	sed -e "s/\`${prefix}/\`wp_/g" \
		-e "s/'${prefix}\(user_roles\|capabilities\|user_level\|user-settings\|user-settings-time\|dashboard_quick_press_last_post_id\)'/'wp_\1'/g" |
	gzip > local/.prod-import.sql.gz
# db-restore.php runs inside WordPress, so it needs an installed site to boot.
wp_cli core is-installed 2>/dev/null ||
	wp_cli core install --url="$LOCAL_URL" --title=tmp --admin_user=admin --admin_password=password --admin_email=admin@example.com --skip-email
wp_cli eval-file /var/www/html/wp-content/psy-repo/scripts/db-restore.php /var/www/html/wp-content/psy-repo/local/.prod-import.sql.gz --skip-plugins --skip-themes
rm -f local/.prod-import.sql.gz

echo "== Run scripts/migrate.sh run"
in_cli env WP_PATH=/var/www/html SITE_URL="$LOCAL_URL" SKIP_THEME_INSTALL=1 BACKUP_DIR=/tmp/rehearsal-backup \
	bash /var/www/html/wp-content/psy-repo/scripts/migrate.sh run

echo "== Point remaining production URLs at the local site"
wp_cli search-replace "https://psychopenhars.com" "$LOCAL_URL" --all-tables-with-prefix --skip-columns=guid
wp_cli search-replace "http://psychopenhars.com" "$LOCAL_URL" --all-tables-with-prefix --skip-columns=guid

echo "== Redirect checks"
bash scripts/check-redirects.sh "$LOCAL_URL"
