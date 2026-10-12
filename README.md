# psychopenhars.com

Migration of psychopenhars.com from WordPress 5.8 + ColibriWP to WordPress 7.1 +
a Twenty Twenty-Five child theme, with clean permalinks.

## Layout

| Path | What |
| --- | --- |
| `theme/psychopenhars/` | Child theme (theme.json, header/footer parts, templates, patterns, self-hosted fonts) |
| `content/` | Block markup for the 4 pages (home, contact, Alice, Gwennaïg), applied with `wp post update` |
| `server/htaccess-redirects.conf` | Legacy `/index.php/...` → clean URL 301 rules, goes above `# BEGIN WordPress` |
| `server/htaccess.example` | What the full `.htaccess` should look like afterwards |
| `scripts/migrate.sh` | Server-side migration: `preflight` (checks + backup) or `run` (backup, core update, themes, content, permalinks, .htaccess) |
| `scripts/db-dump.php`, `scripts/db-restore.php` | DB backup/restore through `wp eval-file`, for hosts without mysql binaries |
| `bin/upload.sh` | Uploads the committed repo to a new `~/psychopenhars-migration-<commit>` folder on the server; never deletes |
| `bin/rehearse-migration.sh` | `npm run rehearse -- <backup-dir>`: runs the real migration locally on a production backup |
| `scripts/check-redirects.sh` | Checks old URLs → single 301 → 200, and that no legacy links remain |
| `.wp-env.json`, `.wp-env.override.json` | Local environment (WP 7.1.3, PHP 8.3, Apache) at http://psychopenhars.wpenv.net |
| `local/seed.php`, `bin/` | Local seeding: pages with the production IDs/slugs, sample uploads |

## Local environment (wp-env)

Requires Node and Docker (or Podman with the Docker socket). `*.wpenv.net` resolves to 127.0.0.1.

```sh
npm install
cp .wp-env.override.example.json .wp-env.override.json   # first time only
npm start            # wp-env start + fetch sample uploads + seed pages
npm run check-redirects
npm run cli -- wp option get permalink_structure
npm stop
```

- Site: http://psychopenhars.wpenv.net. Admin: `/wp-admin` with `admin` / `password`.
- Port 80 and the URL come from `.wp-env.override.json` (not committed, per-machine).
  Create it with `cp .wp-env.override.example.json .wp-env.override.json`. Without it, wp-env uses http://localhost:8888.
- `server/htaccess.example` is what the site's `.htaccess` should contain, so the redirect rules are tested on real Apache.
  wp-env actually serves a gitignored copy, `local/.htaccess`, because the container takes ownership of
  the mapped file. After editing `server/htaccess.example`, run `npm run sync-htaccess`.
- Pages are seeded with the production IDs (11, 13, 26, 154) and slugs, so `?page_id=N` and
  `/index.php/<slug>/` behave exactly as they will on the live site. `npm run seed` re-applies `content/`.
- Seeding runs from `npm start` rather than a wp-env lifecycle hook, because a global
  `WP_ENV_LIFECYCLE_SCRIPT_AFTER_START` (used for Podman permission fixes) would override it.

## Go-live runbook (OVH shared hosting)

The host has WP-CLI 2.12 and PHP 8.3 but no `mysql`/`mysqldump` binaries (so no
`wp db export/import`) and possibly no rsync. The scripts work around both: DB
backups use `scripts/db-dump.php` / `scripts/db-restore.php` through `wp eval-file`.
The live `.htaccess` starts with OVH's HTTPS rule (`%{ENV:HTTPS}`). `migrate.sh`
keeps it first and appends the redirects, then the WordPress block.

`OVH` below is your SSH target (an `ovh` alias in `~/.ssh/config`). WP-CLI is at `~/bin/wp`, which
is not on the PATH of non-interactive SSH commands, hence `WP_BIN`.
The live WordPress folder is `~/psychopenhars`. The migration scripts are uploaded to a
**separate** folder, `~/psychopenhars-migration-<commit>`, and never into the site itself.
`M` below stands for that folder.

1. **Upload the scripts** (committed files only, nothing on the server is deleted):
   `bin/upload.sh OVH`
   This creates `~/psychopenhars-migration-<commit>` and aborts if that folder already exists.
2. **Preflight + backup** (changes nothing on the site):
   `ssh OVH 'WP_BIN=~/bin/wp WP_PATH=~/psychopenhars M/scripts/migrate.sh preflight'`
   This checks PHP/DB versions and the expected pages, prints the current `.htaccess`, and
   writes `~/psychopenhars-backup-<date>/` (`db.sql.gz`, `wp-content.tgz`, `htaccess`).
   It refuses to run if `WP_PATH` isn't a WordPress install, if the scripts folder and the site
   folder overlap, or if the backup would land inside the site (publicly reachable).
   For an extra safety net, also take a database backup in the OVH Manager.
3. **Rehearse locally** on that exact backup:
   `scp -r OVH:psychopenhars-backup-<date> local/prod-backup && npm run rehearse -- local/prod-backup`
   This imports it into wp-env (handling a non-`wp_` table prefix), runs the real
   `migrate.sh run`, and runs the redirect checks. Review http://psychopenhars.wpenv.net
   (log in with your production credentials). `npm run reset` goes back to the demo site.
4. **Go live**: `ssh OVH 'WP_BIN=~/bin/wp WP_PATH=~/psychopenhars M/scripts/migrate.sh run'`
   This takes a fresh backup first, then core 7.1.3, themes, content, Colibri removal, URLs, `.htaccess`.
5. **Verify** from your machine: `scripts/check-redirects.sh https://psychopenhars.com`.
   Then check each page on a phone.
6. **Search Console**: submit `https://psychopenhars.com/wp-sitemap.xml`.
7. **Clean up** once you're happy: remove `~/psychopenhars-migration-<commit>` on the server.
   Keep the `~/psychopenhars-backup-*` folders for a while.

**Rollback** (on the server, `B=~/psychopenhars-backup-<date>`). This restores files *inside*
the site folder; double-check the `cd` target:

```sh
cd ~/psychopenhars                      # the live WordPress folder
~/bin/wp core download --version=5.8.18 --force --skip-content
~/bin/wp eval-file ~/psychopenhars-migration-<commit>/scripts/db-restore.php $B/db.sql.gz --skip-plugins --skip-themes
rm -rf wp-content && tar -xzf $B/wp-content.tgz
cp $B/htaccess .htaccess
```

## Content status

- Page content signed off by both practitioners (2026-10-12).
- `quimper.jpg` (homepage hero): licence confirmed (2026-10-12).
- Possible later improvements: photos of the new Résidence St Corentin office, and a portrait of Gwennaïg.
  Until then, the home cards use initials for both practitioners.
