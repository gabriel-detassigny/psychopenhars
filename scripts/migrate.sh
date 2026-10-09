#!/usr/bin/env bash
# One-shot migration of psychopenhars.com: WP 5.8 + Colibri -> WP 7.1 +
# Twenty Twenty-Five child theme + clean permalinks.
#
# Run ON THE SERVER (or staging copy), from the repo checkout uploaded there:
#   WP_PATH=/path/to/wordpress SITE_URL=https://psychopenhars.com scripts/migrate.sh
#
# Steps are safe to re-run. A DB + .htaccess backup is taken first.
set -euo pipefail

WP_PATH="${WP_PATH:?set WP_PATH to the WordPress root}"
SITE_URL="${SITE_URL:-https://psychopenhars.com}"
WP_VERSION="${WP_VERSION:-7.1.3}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${BACKUP_DIR:-$HOME/psychopenhars-backup-$STAMP}"

wp() { command wp --path="$WP_PATH" "$@"; }

# Page IDs on the live site (audited 2026-10-09).
HOME_ID=11
CONTACT_ID=13
ALICE_ID=26
GWENNAIG_ID=154
SAMPLE_ID=2
COLIBRI_FRONT_ID=39

echo "== 1. Backup -> $BACKUP"
mkdir -p "$BACKUP"
wp db export "$BACKUP/db.sql"
[[ -f "$WP_PATH/.htaccess" ]] && cp "$WP_PATH/.htaccess" "$BACKUP/htaccess"
tar -czf "$BACKUP/uploads.tgz" -C "$WP_PATH/wp-content" uploads
wp core version > "$BACKUP/core-version.txt"
wp option get permalink_structure > "$BACKUP/permalink_structure.txt" || true

echo "== 2. Core $(wp core version) -> $WP_VERSION"
wp core update --version="$WP_VERSION"
wp core update-db
wp core verify-checksums

echo "== 3. Themes"
wp theme install twentytwentyfive --force
rsync -a --delete "$REPO/theme/psychopenhars/" "$WP_PATH/wp-content/themes/psychopenhars/"
wp theme activate psychopenhars

echo "== 4. Content"
wp post update "$HOME_ID" "$REPO/content/home.html" --post_title="Accueil"
wp post update "$CONTACT_ID" "$REPO/content/contact.html" --post_title="Contact & accès"
wp post update "$ALICE_ID" "$REPO/content/alice-reutlinger.html" --post_title="Alice Reutlinger, psychologue"
wp post update "$GWENNAIG_ID" "$REPO/content/gwennaig-le-nouy.html" --post_title="Gwennaïg Le Nouy, psychologue"
wp option update show_on_front page
wp option update page_on_front "$HOME_ID"
wp post delete "$SAMPLE_ID" "$COLIBRI_FRONT_ID" --force || true
wp option update blogdescription "Psychologues à Quimper — Résidence St Corentin, 75 rue de Bénodet"

echo "== 5. Remove Colibri"
wp option delete theme_mods_colibri-wp || true
wp theme delete colibri-wp || true

echo "== 6. Clean URLs"
wp search-replace "http://psychopenhars.com/index.php/" "$SITE_URL/" --all-tables-with-prefix --skip-columns=guid
wp search-replace "$SITE_URL/index.php/" "$SITE_URL/" --all-tables-with-prefix --skip-columns=guid
wp search-replace "http://psychopenhars.com/wp-content/" "$SITE_URL/wp-content/" --all-tables-with-prefix --skip-columns=guid
wp rewrite structure '/%postname%/'

# Prepend the legacy redirects to the existing .htaccess (which may hold the
# host's HTTP->HTTPS rule), then let WordPress write its own block.
touch "$WP_PATH/.htaccess"
if ! grep -q 'psychopenhars: legacy URL redirects' "$WP_PATH/.htaccess"; then
	cat "$REPO/server/htaccess-redirects.conf" - < "$WP_PATH/.htaccess" > "$WP_PATH/.htaccess.new"
	mv "$WP_PATH/.htaccess.new" "$WP_PATH/.htaccess"
fi
# WP-CLI only writes .htaccess with --hard when it knows mod_rewrite is loaded,
# which it can't detect from the CLI, so append the standard block ourselves.
if ! grep -q '# BEGIN WordPress' "$WP_PATH/.htaccess"; then
	sed -n '/^# BEGIN WordPress/,/^# END WordPress/p' "$REPO/server/htaccess.example" >> "$WP_PATH/.htaccess"
fi
wp rewrite flush
wp cache flush

echo "== Done. Backup in $BACKUP"
echo "Next: review $WP_PATH/.htaccess, then run scripts/check-redirects.sh $SITE_URL"
