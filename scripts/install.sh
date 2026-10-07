#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
set -a
source .env
set +a

COMPOSE="${COMPOSE:-docker compose}"
THEME_SLUG="${THEME_SLUG:-starter}"

wp() {
  $COMPOSE --profile tools run --rm --no-deps wpcli "$@"
}

echo "Waiting for the database..."
until wp db check >/dev/null 2>&1; do
  sleep 2
done

if ! wp core is-installed >/dev/null 2>&1; then
  echo "Installing WordPress..."
  wp core install \
    --url="$WP_HOME" \
    --title="${WP_TITLE:-Starter}" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email
else
  echo "WordPress is already installed."
fi

if [[ -n "${WP_LOCALE:-}" && "$WP_LOCALE" != "en_US" ]]; then
  wp language core install "$WP_LOCALE" --activate
fi

wp plugin delete akismet hello || true

if [[ -n "${WP_PLUGINS:-}" ]]; then
  # shellcheck disable=SC2086
  wp plugin install $WP_PLUGINS --activate
  if [[ -n "${WP_LOCALE:-}" && "$WP_LOCALE" != "en_US" ]]; then
    wp language plugin install --all "$WP_LOCALE" || true
  fi
fi

if wp theme is-installed "$THEME_SLUG" >/dev/null 2>&1; then
  wp theme activate "$THEME_SLUG"
else
  echo "Theme $THEME_SLUG is not installed yet." >&2
  exit 1
fi

wp theme delete twentytwentytwo twentytwentythree twentytwentyfour twentytwentyfive || true

wp rewrite structure '/%postname%/' --hard
wp rewrite flush --hard

echo "Install complete."
echo "Site: $WP_HOME"
echo "Admin: $WP_HOME/wp-admin  ($WP_ADMIN_USER / $WP_ADMIN_PASSWORD)"
