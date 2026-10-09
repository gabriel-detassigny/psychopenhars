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
| `scripts/migrate.sh` | Server-side migration (backup, core update, theme, content, permalinks, .htaccess) |
| `scripts/check-redirects.sh` | Checks old URLs → single 301 → 200, and that no legacy links remain |
| `.wp-env.json`, `.wp-env.override.json` | Local environment (WP 7.1.3, PHP 8.3, Apache) at http://psychopenhars.wpenv.net |
| `local/seed.php`, `bin/` | Local seeding: pages with the production IDs/slugs, sample uploads |

## Local environment (wp-env)

Requires Node and Docker (or Podman with the Docker socket). `*.wpenv.net` resolves to 127.0.0.1.

```sh
npm install
npm start            # wp-env start + fetch sample uploads + seed pages
npm run check-redirects
npm run cli -- wp option get permalink_structure
npm stop
```

- Site: http://psychopenhars.wpenv.net. Admin: `/wp-admin` with `admin` / `password`.
- Port 80 and the URL come from `.wp-env.override.json`. Change the port there if 80 is taken.
- `server/htaccess.example` is mapped as the site's `.htaccess`, so the redirect rules are tested on real Apache.
  It's a single-file bind mount, so after editing it with a tool that replaces the file (e.g. `sed -i`),
  restart the container: `docker restart $(docker ps -qf name=psychopenhars.*wordpress-1)`.
- Pages are seeded with the production IDs (11, 13, 26, 154) and slugs, so `?page_id=N` and
  `/index.php/<slug>/` behave exactly as they will on the live site. `npm run seed` re-applies `content/`.
- Seeding runs from `npm start` rather than a wp-env lifecycle hook, because a global
  `WP_ENV_LIFECYCLE_SCRIPT_AFTER_START` (used for Podman permission fixes) would override it.

## Go-live runbook

1. **Staging first**: clone prod (`wp db export` + files) to a staging copy and run
   steps 2–4 there. Then repeat on prod during a short maintenance window.
2. Upload this repo to the server, e.g. `rsync -a --exclude local ./ server:~/psychopenhars/`.
3. Run `WP_PATH=/path/to/wordpress SITE_URL=https://psychopenhars.com ~/psychopenhars/scripts/migrate.sh`.
   It backs up DB, uploads and `.htaccess` into `~/psychopenhars-backup-<date>/` first.
4. Review the resulting `.htaccess`, then from your machine run
   `scripts/check-redirects.sh https://psychopenhars.com`.
5. Search Console: submit `https://psychopenhars.com/wp-sitemap.xml`.

**Rollback**: `wp db import <backup>/db.sql`, `wp core update --version=5.8.18 --force`,
restore `<backup>/htaccess`, reinstall colibri-wp.

## Open content questions

- `quimper.jpg` (homepage hero) has an EXIF copyright of "bbsferrari", which looks like a stock photo. Confirm the licence, or replace it with your own photo of Quimper or the new office.
- Office photos on the old site show the previous premises (Centre Delta / Creac'h Gwen), so they're no longer used. Photos of the new Résidence St Corentin office would help.
- Gwennaïg has no portrait on the site. Home cards use initials for both practitioners so they stay consistent.
