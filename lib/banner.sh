#!/usr/bin/env bash
# lib/banner.sh — LazyVim-ish block banner (terminal + shared art)

# pagga-style "LAZY" — works without figlet/toilet
lazy_banner_art() {
  cat <<'EOF'
░█░░░█▀█░▀▀█░█░█
░█░░░█▀█░▄▀░░░█░
░▀▀▀░▀░▀░▀▀▀░░▀░
EOF
}

lazy_banner_colors() {
  if [ -t 1 ] || [ "${LAZY_BANNER_FORCE_COLOR:-}" = "1" ]; then
    LAZY_BANNER_MAIN="$(printf '\033[38;5;117m')"
    LAZY_BANNER_SHADOW="$(printf '\033[38;5;238m')"
    LAZY_BANNER_DIM="$(printf '\033[2m\033[38;5;245m')"
    LAZY_BANNER_RESET="$(printf '\033[0m')"
  else
    LAZY_BANNER_MAIN=""
    LAZY_BANNER_SHADOW=""
    LAZY_BANNER_DIM=""
    LAZY_BANNER_RESET=""
  fi
}

# Print one art line: block chars colored, rest dim (LazyVim-ish).
lazy_banner_print_line() {
  local line="$1"
  local ch
  local i=0
  printf '  '
  while [ "$i" -lt "${#line}" ]; do
    ch="${line:$i:1}"
    case "$ch" in
      ░|█|▀|▄|─|│|╻|╹|━|┓|┛|┏|┗|┣|┫|╋|╸|╺)
        printf '%b%s%b' "$LAZY_BANNER_MAIN" "$ch" "$LAZY_BANNER_RESET"
        ;;
      *)
        printf '%s' "$ch"
        ;;
    esac
    i=$((i + 1))
  done
  printf '\n'
}

lazy_print_banner() {
  local tagline="${1:-too lazy to type}"
  local line

  lazy_banner_colors
  printf '\n'

  # best: toilet pagga + metal filter (LazyVim-ish blue blocks)
  if command -v toilet >/dev/null 2>&1; then
    if toilet -f pagga --filter metal LAZY 2>/dev/null | sed 's/^/  /'; then
      printf '  %s·  %s%s\n\n' "$LAZY_BANNER_DIM" "$tagline" "$LAZY_BANNER_RESET"
      return
    fi
    if toilet -f pagga --filter gay LAZY 2>/dev/null | sed 's/^/  /'; then
      printf '  %s·  %s%s\n\n' "$LAZY_BANNER_DIM" "$tagline" "$LAZY_BANNER_RESET"
      return
    fi
  fi

  # fallback: embedded block art + shadow offset
  while IFS= read -r line; do
    printf '  %b %s%b\n' "$LAZY_BANNER_SHADOW" "$line" "$LAZY_BANNER_RESET"
  done <<EOF
$(lazy_banner_art)
EOF

  while IFS= read -r line; do
    lazy_banner_print_line "$line"
  done <<EOF
$(lazy_banner_art)
EOF

  printf '  %s·  %s%s\n\n' "$LAZY_BANNER_DIM" "$tagline" "$LAZY_BANNER_RESET"
}

lazy_print_banner_small() {
  local title="${1:-lazy}"
  lazy_banner_colors
  printf '\n  %b%s%b  %s·  %s%s\n\n' \
    "$LAZY_BANNER_MAIN" "$title" "$LAZY_BANNER_RESET" \
    "$LAZY_BANNER_DIM" "${2:-}" "$LAZY_BANNER_RESET"
}
