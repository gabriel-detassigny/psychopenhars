#!/usr/bin/env bash
# Verify every legacy URL 301s (in one hop) to its clean URL, and that the
# clean URLs answer 200. Usage: scripts/check-redirects.sh [base-url]
set -uo pipefail

BASE="${1:-https://psychopenhars.com}"
BASE="${BASE%/}"
fail=0

# old path | expected Location (path) after exactly one 301
REDIRECTS=(
	"/index.php/contact/|/contact/"
	"/index.php/contact|/contact/"
	"/index.php/alice-reutlinger/|/alice-reutlinger/"
	"/index.php/gwennaig-le-nouy/|/gwennaig-le-nouy/"
	"/index.php/cabinet-de-psychologues/|/"
	"/index.php/colibri-wp/|/"
	"/index.php/sample-page/|/"
	"/colibri-wp/|/"
	"/sample-page/|/"
	"/index.php/feed/|/feed/"
	"/?page_id=11|/"
	"/?page_id=13|/contact/"
	"/?page_id=26|/alice-reutlinger/"
	"/?page_id=154|/gwennaig-le-nouy/"
)

OK_200=(
	"/"
	"/contact/"
	"/alice-reutlinger/"
	"/gwennaig-le-nouy/"
	"/feed/"
	"/wp-sitemap.xml"
	"/wp-content/uploads/2021/09/alice.png"
)

# Follow redirects up to the final URL, printing "hops final_code final_url".
resolve() {
	curl -s -o /dev/null -L --max-redirs 5 -A "psychopenhars-check" \
		-w '%{num_redirects} %{http_code} %{url_effective}' "$1"
}

for pair in "${REDIRECTS[@]}"; do
	from="${pair%%|*}"
	to="${pair##*|}"
	first=$(curl -s -o /dev/null -A "psychopenhars-check" -w '%{http_code} %{redirect_url}' "$BASE$from")
	read -r hops code final <<<"$(resolve "$BASE$from")"
	if [[ "${first%% *}" == "301" && "$final" == "$BASE$to" && "$code" == "200" ]]; then
		if [[ "$hops" == "1" ]]; then
			echo "ok    $from -> $to"
		else
			echo "warn  $from -> $to ($hops hops)"
		fi
	else
		echo "FAIL  $from: first=[$first] final=[$code $final] expected 301 -> $BASE$to"
		fail=1
	fi
done

for path in "${OK_200[@]}"; do
	code=$(curl -s -o /dev/null -A "psychopenhars-check" -w '%{http_code}' "$BASE$path")
	if [[ "$code" == "200" ]]; then
		echo "ok    $path 200"
	else
		echo "FAIL  $path returned $code"
		fail=1
	fi
done

# No legacy links left in rendered pages.
for path in / /contact/ /alice-reutlinger/ /gwennaig-le-nouy/; do
	if curl -s -A "psychopenhars-check" "$BASE$path" | grep -qE 'index\.php/|http://psychopenhars'; then
		echo "FAIL  $path still contains index.php/ or http:// links"
		fail=1
	fi
done

exit $fail
