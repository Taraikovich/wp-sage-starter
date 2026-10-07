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
THEME_NAME="${THEME_NAME:-Starter}"
THEME_DIR="wordpress/wp-content/themes/$THEME_SLUG"
WP_UID="${WP_UID:-$(id -u)}"
WP_GID="${WP_GID:-$(id -g)}"
export THEME_SLUG THEME_NAME

composer_wp() {
  $COMPOSE run --rm --no-deps --user "$WP_UID:$WP_GID" \
    -w /var/www/html/wp-content/themes \
    wordpress composer "$@"
}

if [[ ! -f "$THEME_DIR/style.css" ]]; then
  echo "Creating Sage theme '$THEME_SLUG'..."
  rm -rf "$THEME_DIR"
  composer_wp create-project roots/sage "$THEME_SLUG" --no-interaction

  python3 - <<'PY'
import os
import re
from pathlib import Path

slug = os.environ["THEME_SLUG"]
name = os.environ["THEME_NAME"]
theme = Path("wordpress/wp-content/themes") / slug
vite = theme / "vite.config.js"
style = theme / "style.css"

if vite.exists():
    text = vite.read_text()
    text = re.sub(
        r"base: ['\"]/app/themes/sage/public/build/['\"],",
        f"base: '/wp-content/themes/{slug}/public/build/',",
        text,
    )
    if "origin: 'http://localhost:5173'" not in text:
        server_block = """  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
    cors: true,
    origin: 'http://localhost:5173',
  },"""
        if "  server:" in text:
            text = re.sub(r"\n  server: \{.*?\n  \},", "\n" + server_block, text, count=1, flags=re.S)
        elif text.rstrip().endswith("})"):
            text = text.rstrip()[:-2] + server_block + "\n})\n"
    vite.write_text(text)

if style.exists():
    out = []
    for line in style.read_text().splitlines():
        if line.startswith("Theme Name:"):
            out.append(f"Theme Name: {name}")
        elif line.startswith("Text Domain:"):
            out.append(f"Text Domain: {slug}")
        else:
            out.append(line)
    style.write_text("\n".join(out) + "\n")
PY
fi

echo "Installing npm dependencies and building assets..."
$COMPOSE --profile dev run --rm --no-deps node npm install
$COMPOSE --profile dev run --rm --no-deps node npm run build
