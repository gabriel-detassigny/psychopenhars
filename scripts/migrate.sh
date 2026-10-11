#!/usr/bin/env bash
# One-shot migration of psychopenhars.com: WP 5.8 + Colibri -> WP 7.1 +
# Twenty Twenty-Five child theme + clean permalinks.
#
# Run ON THE SERVER from the repo copy uploaded there:
#   WP_PATH=~/www scripts/migrate.sh preflight   # checks + backup, changes nothing
#   WP_PATH=~/www scripts/migrate.sh run         # backup + full migration
#
# Written for OVH shared hosting: no mysql/mysqldump binary (the DB backup
# uses scripts/db-dump.php through WP-CLI) and no rsync.
set -euo pipefail

MODE="${1:-}"
[[ "$MODE" == "preflight" || "$MODE" == "run" ]] || {
	echo "Usage: WP_PATH=/path/to/wordpress $0 preflight|run" >&2
	exit 2
}

WP_PATH="${WP_PATH:?set WP_PATH to the WordPress root}"
SITE_URL="${SITE_URL:-https://psychopenhars.com}"
WP_VERSION="${WP_VERSION:-7.1.3}"
WP_BIN="${WP_BIN:-wp}"
# Set to 1 when both themes are already in place (local rehearsal mounts them).
SKIP_THEME_INSTALL="${SKIP_THEME_INSTALL:-0}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${BACKUP_DIR:-$HOME/psychopenhars-backup-$STAMP}"

wp() { command "$WP_BIN" --path="$WP_PATH" "$@"; }
# For steps that must not load the old theme (it may not survive WP 7.1).
wp_bare() { wp --skip-themes --skip-plugins "$@"; }

# Page IDs on the live site (audited 2026-10-09).
HOME_ID=11
CONTACT_ID=13
ALICE_ID=26
GWENNAIG_ID=154
SAMPLE_ID=2
COLIBRI_FRONT_ID=39

echo "== Preflight"
current="$(wp_bare core version)"
db_version="$(wp_bare eval 'global $wpdb; echo $wpdb->db_version();')"
echo "WordPress $current, database server $db_version, PHP $(php -r 'echo PHP_VERSION;')"
php -r 'exit(version_compare(PHP_VERSION, "7.4", ">=") ? 0 : 1);' || { echo "PHP >= 7.4 required" >&2; exit 1; }
wp_bare eval 'global $wpdb; exit( version_compare( $wpdb->db_version(), "5.5.5", ">=" ) ? 0 : 1 );' || {
	echo "Database server >= 5.5.5 required" >&2
	exit 1
}
for id in $HOME_ID $CONTACT_ID $ALICE_ID $GWENNAIG_ID; do
	wp_bare post get "$id" --field=post_name >/dev/null || { echo "Expected page $id is missing" >&2; exit 1; }
done
[[ -f "$WP_PATH/.htaccess" ]] && { echo "Current .htaccess:"; sed 's/^/    /' "$WP_PATH/.htaccess"; }

echo "== Backup -> $BACKUP"
mkdir -p "$BACKUP"
wp_bare eval-file "$REPO/scripts/db-dump.php" "$BACKUP/db.sql.gz"
[[ -f "$WP_PATH/.htaccess" ]] && cp "$WP_PATH/.htaccess" "$BACKUP/htaccess"
tar -czf "$BACKUP/wp-content.tgz" -C "$WP_PATH" wp-content
echo "$current" > "$BACKUP/core-version.txt"
ls -lh "$BACKUP"

if [[ "$MODE" == "preflight" ]]; then
	echo "== Preflight OK, nothing changed. Backup in $BACKUP"
	exit 0
fi

echo "== Core $current -> $WP_VERSION"
wp_bare core update --version="$WP_VERSION"
wp_bare core update-db
wp_bare core verify-checksums

echo "== Themes"
if [[ "$SKIP_THEME_INSTALL" != "1" ]]; then
	wp_bare theme install twentytwentyfive --force
	rm -rf "$WP_PATH/wp-content/themes/psychopenhars"
	cp -R "$REPO/theme/psychopenhars" "$WP_PATH/wp-content/themes/psychopenhars"
fi
wp_bare theme activate psychopenhars

echo "== Content"
wp post update "$HOME_ID" "$REPO/content/home.html" --post_title="Accueil"
wp post update "$CONTACT_ID" "$REPO/content/contact.html" --post_title="Contact & accès"
wp post update "$ALICE_ID" "$REPO/content/alice-reutlinger.html" --post_title="Alice Reutlinger, psychologue"
wp post update "$GWENNAIG_ID" "$REPO/content/gwennaig-le-nouy.html" --post_title="Gwennaïg Le Nouy, psychologue"
wp option update show_on_front page
wp option update page_on_front "$HOME_ID"
wp post delete "$SAMPLE_ID" "$COLIBRI_FRONT_ID" --force || true
wp option update blogdescription "Psychologues à Quimper"

echo "== Remove Colibri"
wp option delete theme_mods_colibri-wp || true
wp theme delete colibri-wp || true

echo "== Clean URLs"
REPLACEMENTS=(
	"http://psychopenhars.com/index.php/|$SITE_URL/"
	"https://psychopenhars.com/index.php/|$SITE_URL/"
	"http://psychopenhars.com/wp-content/|$SITE_URL/wp-content/"
)
for pair in "${REPLACEMENTS[@]}"; do
	wp search-replace "${pair%%|*}" "${pair##*|}" --all-tables-with-prefix --skip-columns=guid
done
wp rewrite structure '/%postname%/'

# Append the legacy redirects after whatever the live .htaccess already holds
# (OVH's HTTP->HTTPS rule must stay first), then the WordPress block. WP-CLI
# can't detect mod_rewrite from the CLI, so it won't write that block itself.
touch "$WP_PATH/.htaccess"
if ! grep -q 'psychopenhars: legacy URL redirects' "$WP_PATH/.htaccess"; then
	{ echo; cat "$REPO/server/htaccess-redirects.conf"; } >> "$WP_PATH/.htaccess"
fi
if ! grep -q '# BEGIN WordPress' "$WP_PATH/.htaccess"; then
	{ echo; sed -n '/^# BEGIN WordPress/,/^# END WordPress/p' "$REPO/server/htaccess.example"; } >> "$WP_PATH/.htaccess"
fi
wp rewrite flush
wp cache flush

echo "== Done. Backup in $BACKUP"
echo "Final .htaccess:"
sed 's/^/    /' "$WP_PATH/.htaccess"
echo "Next: scripts/check-redirects.sh $SITE_URL (from your machine)"
